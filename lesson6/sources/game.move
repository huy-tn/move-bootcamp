// hoan thien code de module co the publish duoc
module lesson6::hero_game {
    use std::option::{Self, Option};
    use std::string::{Self, String};

    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;

    const MIN_SWORD_COST: u64 = 100;
    const EINSUFFICIENT_FUNDS: u64 = 3;
    const EMONSTER_WON: u64 = 4;


    // Dien them cac ability phu hop cho cac object
    struct Hero has key, store {
        id: UID,
        name: String,
        hp: u64,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID
    }

    // Dien them cac ability phu hop cho cac object
    struct Sword has key, store {
        id: UID,
        // attack: u64,
        strength: u64,
        game_id: ID,
    }

    // Dien them cac ability phu hop cho cac object
    struct Armor has key, store {
        id: UID,
        defense: u64,
        game_id: ID,
    }

    // Dien them cac ability phu hop cho cac object
    struct Monster has key {
        id: UID,
        hp: u64,
        strength: u64,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address,
    }

    struct GameAdmin has key {
        id: UID,
        game_id: ID,
        monsters: u64,
    }


    // hoan thien function de khoi tao 1 game moi
    fun init(ctx: &mut TxContext) {
        let sender = tx_context:: sender (ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);
        transfer::freeze_object (
            GameInfo {
                id,
                admin: sender,
            }
        );
        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                monsters: 0,
            },
            sender
        )

    }

    public entry fun acquire_hero(
        game: &GameInfo, name: String, payment1: Coin<SUI>, payment2: Coin<SUI>, ctx: &mut TxContext
    ) {
        let sword = create_sword(game, payment1, ctx);
        let armor = create_armor(game, payment2, ctx);
        let hero = create_hero(game, name, sword, armor, ctx);
        
        transfer::public_transfer(hero, tx_context::sender(ctx));
    }


    // function de create cac vat pham, nhan vat trong game.
    fun create_hero(game: &GameInfo, name: String, sword: Sword, armor: Armor, ctx: &mut TxContext): Hero {
        Hero {
            id: object::new(ctx),
            name,
            hp: 100,
            experience: 0,
            sword: option::some(sword),
            armor: option::some(armor),
            game_id: object::id(game),
        }

    }

    fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        let value = coin::value(&payment);
        assert! (value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS); 
        transfer::public_transfer(payment, game.admin);
        // let magic = (value - MIN_SWORD_COST) / MIN_SWORD_COST;
        Sword {
            id: object:: new(ctx),
            // magic: math::min(magic, MAX_MAGIC),
            strength: value / 10,
            game_id: object::id(game),
        }
    }

    fun create_armor(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Armor {
        let value = coin::value(&payment);

        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS);
        transfer::public_transfer(payment, game.admin);

        Armor {
            id: object::new(ctx),
            defense: value / 20,
            game_id: object::id(game),
        }

    }

    // function de create quai vat, chien dau voi hero, chi admin moi co quyen su dung function nay
    // Goi y: khoi tao them 1 object admin.
    public entry fun create_monster(
        game: &GameInfo, admin: &mut GameAdmin, hp: u64, strength: u64, player: address, ctx: &mut TxContext
    ) {
        admin.monsters = admin.monsters + 1;
        transfer::transfer(
            Monster { id: object::new(ctx), hp, strength, game_id: object::id(game) },
            player
        );

    }

    // func de tang diem kinh nghiem cho hero sau khi giet duoc quai vat
    public fun level_up_hero(hero: &mut Hero, exp_gain: u64) {
        hero.experience = hero.experience + exp_gain;
    }
    public fun level_up_sword(sword: &mut Sword, exp_gain: u64) {
        sword.strength = sword.strength + exp_gain;
    }
    public fun level_up_armor(armor: &mut Armor, exp_gain: u64) {
        armor.defense = armor.defense + exp_gain;
    }

    // Tan cong, hoan thien function de hero va monster danh nhau
    // goi y: kiem tra so diem hp va strength cua hero va monster, lay hp tru di so suc manh moi lan tan cong. HP cua ai ve 0 truoc nguoi do thua
    public entry fun attack_monster(game: &GameInfo, hero: &mut Hero, monster: Monster, ctx: &TxContext) {
        let Monster { id: monster_id, hp, strength: monster_strength, game_id: _ } = monster;
        let monster_hp = hp;
        let hero_strength = hero_strength(hero);

        let exp_gain: u64 = monster_hp;
        let hero_hp = hero.hp;
        while (monster_hp > hero_strength) {
            monster_hp = monster_hp - hero_strength;
            assert!(hero_hp >= monster_strength, EMONSTER_WON);
            hero_hp = hero_hp - monster_strength;
        };
        
        hero.hp = hero_hp;

        level_up_hero(hero, exp_gain);

        if (option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), exp_gain);
        };

        if (option::is_some(&hero.armor)) {
            level_up_armor(option::borrow_mut(&mut hero.armor), exp_gain);
        };

        // level_up_armor(armor, exp_gain);
        object::delete(monster_id);
    }

    public fun hero_strength(hero: &Hero): u64 {
        if (hero.hp == 0) {
            return 0
        };
        let sword_strength = if (option::is_some(&hero.sword)) {
            sword_strength(option::borrow(&hero.sword))
        } else {
            0
        };
        hero.hp + sword_strength
        
    }

    public fun sword_strength(sword: &Sword): u64 {
        sword.strength
    }
}
