module game_hero::sea_hero_helper {
    use game_hero::sea_hero::{Self, SeaMonster, VBI_TOKEN};
    use game_hero::hero::Hero;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const EINVALID_HELPER_REWARD: u64 = 0;

    struct HelpMeSlayThisMonster has key {
        id: UID,
        monster: SeaMonster,
        monster_owner: address,
        helper_reward: u64,
    }

    public entry fun create_help(monster: SeaMonster, helper_reward: u64, helper: address, ctx: &mut TxContext,) {
        // create a helper to help you attack strong monster
        assert!(sea_hero::monster_reward(&monster) > helper_reward, EINVALID_HELPER_REWARD);
        transfer::transfer(
            HelpMeSlayThisMonster {
                id: object::new(ctx),
                monster,
                monster_owner: tx_context::sender(ctx),
                helper_reward
            },
            helper
        );
    }

    public entry fun attack(hero: &Hero, wrapper: HelpMeSlayThisMonster, ctx: &mut TxContext) {
        let helper_reward: Coin<VBI_TOKEN> = slay(hero, wrapper, ctx);
        transfer::public_transfer(helper_reward, tx_context::sender(ctx));
    }

    public fun slay(hero: &Hero, wrapper: HelpMeSlayThisMonster, ctx: &mut TxContext,): Coin<VBI_TOKEN> {
        // hero & hero helper will collaborative to attack monster
        let HelpMeSlayThisMonster {
            id,
            monster,
            monster_owner,
            helper_reward,
        } = wrapper;
        object::delete(id);
        let owner_reward = sea_hero::slay(hero, monster);
        let helper_reward = coin::take(&mut owner_reward, helper_reward, ctx);
        transfer::public_transfer(coin::from_balance(owner_reward, ctx), monster_owner);
        helper_reward
    }

    public fun return_to_owner(wrapper: HelpMeSlayThisMonster) {
        // after attack success, hero_helper will return to owner
        let HelpMeSlayThisMonster {
            id,
            monster,
            monster_owner,
            helper_reward: _,
        } = wrapper;
        object::delete(id);
        transfer::public_transfer(monster, monster_owner);
    }

    public fun owner_reward(wrapper: &HelpMeSlayThisMonster): u64 {
        // the amount will reward for hero helper
        sea_hero::monster_reward(&wrapper.monster) - wrapper.helper_reward
    }
}
