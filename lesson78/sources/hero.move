module game_hero::hero {
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::math;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};

    struct Hero has key, store {
        id: UID,
        hp: u64,
        mana: u64,
        level: u8,
        experience: u64,
        sword: Option<Sword>,
        armor: Option<Armor>,
        game_id: ID,
    }

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
        game_id: ID,
    }

    struct Potion has key, store {
        id: UID,
        potency: u64,
        game_id: ID,
    }

    struct Armor has key,store {
        id: UID,
        guard: u64,
        game_id: ID,
    }

    struct Monster has key {
        id: UID,
        hp: u64,
        strength: u64,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address
    }

    struct GameAdmin has key {
        id: UID,
        monsters_created: u64,             
        potions_created: u64,
        game_id: ID,
    }

    struct MonsterSlainEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        monster: ID,
        game_id: ID,
    }

    const MAX_HP: u64 = 1000;

    const MAX_MAGIC: u64 = 10;
    const MIN_SWORD_COST: u64 = 100;
    const MIN_ARMOR_COST: u64 = 200;

    const MAX_GUARD: u64 = 50;
    const EMONSTER_WON: u64 = 0;
    const EHERO_TIRED: u64 = 1;

    const ENOT_ADMIN: u64 = 2;

    const EINSUFFICIENT_FUNDS: u64 = 3;

    const ENO_SWORD: u64 = 4;

    const ASSERT_ERR: u64 = 5;
    const ID_MISMATCH_ERR: u64 = 403;

    const ESAME_HERO: u64 = 6;

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
        // Create a new game with Info & Admin
        create(ctx);
    }
    
    public fun new_game(ctx: &mut TxContext) {
        // Create a new game with Info & Admin
        create(ctx);
    }

    fun create(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);
        transfer::freeze_object(
            GameInfo {
                id,
                admin: sender,
            }
        );
        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                monsters_created: 0,
                potions_created: 0,
            },
            sender
        )
    }


    // --- Gameplay ---
    public entry fun attack(game: &GameInfo, hero: &mut Hero, monster: Monster, ctx: &TxContext) {
        /// Completed this code to hero can attack Monster
        /// after attack, if success hero will up_level hero, up_level_sword and up_level_armor.
        check_id(game, hero.game_id);
        check_id(game, monster.game_id);
        let Monster { id: monster_id, strength: monster_strength, hp, game_id: _ } = monster;
        let hero_strength = hero_strength(hero);
        let hero_guard = hero_guard(hero);
        let monster_hp = hp;
        let hero_hp = hero.hp;
        monster_strength = math::max(1, monster_strength - hero_guard);
        while (monster_hp > hero_strength) {
            monster_hp = monster_hp - hero_strength;
            assert!(hero_hp >= monster_strength, EMONSTER_WON);
            hero_hp = hero_hp - monster_strength;
        };

        hero.hp = hero_hp;
        // hero.experience = hero.experience + hp;
        level_up_hero(hero);
        if (option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), 5);
        };
        if (option::is_some(&hero.armor)) {
            level_up_armor(option::borrow_mut(&mut hero.armor), 1);
        };

        event::emit(MonsterSlainEvent {
            slayer_address: tx_context::sender(ctx),
            hero: object::uid_to_inner(&hero.id),
            monster: object::uid_to_inner(&monster_id),
            game_id: id(game)
        });
        object::delete(monster_id);
    }

    public entry fun p2p_play(game: &GameInfo, hero1: &mut Hero, hero2: &mut Hero, ctx: &TxContext) {
        assert!(object::id(hero1) != object::id(hero2), ESAME_HERO);
        let hero1_strength: u64 = hero_strength(hero1);
        let hero2_strength: u64 = hero_strength(hero2);

        // simple logic to decide who win
        if (hero1_strength > hero2_strength) {
            level_up_hero(hero1);
        }
        else {
            level_up_hero(hero2);
        }
    }

    public fun level_up_hero(hero: &mut Hero) {
        hero.experience = hero.experience + 50;
        if (hero.experience >= 100) {
            hero.level = hero.level + 1;
            hero.mana = hero.mana + 100;
            hero.experience = hero.experience - 100;
        }
    }

    public fun hero_strength(hero: &Hero): u64 {
        // calculator strength
        if (hero.hp == 0) {
            return 0
        };
        let sword_strength = if (option::is_some(&hero.sword)) {
            sword_strength(option::borrow(&hero.sword))
        } else {
            0
        };
        (hero.experience * hero.hp) + sword_strength
    }

    public fun hero_guard(hero: &Hero): u64 {
        // calculator strength
        if (hero.hp == 0) {
            return 0
        };
        let armor_guard = if (option::is_some(&hero.armor)) {
            armor_guard(option::borrow(&hero.armor))
        } else {
            0
        };
        armor_guard
    }


    public fun level_up_sword(sword: &mut Sword, amount: u64) {
        // up power/strength for sword
        sword.strength = sword.strength + amount;
    }

    public fun level_up_armor(armor: &mut Armor, amount: u64) {
        armor.guard = armor.guard + amount;
    }


    public fun armor_guard(armor: &Armor): u64 {
        armor.guard
    }

    public fun sword_strength(sword: &Sword): u64 {
        // calculator strength of sword follow magic + strength
        sword.magic + sword.strength
    }

    public fun heal(hero: &mut Hero, potion: Potion) {
        // use the potion to heal
        assert!(hero.game_id == potion.game_id, ID_MISMATCH_ERR);
        let Potion { id, potency, game_id: _ } = potion;
        object::delete(id);
        let new_hp = hero.hp + potency;
        hero.hp = math::min(new_hp, MAX_HP)
    }

    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        // change another sword
        option::swap_or_fill(&mut hero.sword, new_sword)
    }

    // --- Object creation ---
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        // Create a sword, streight depends on payment amount
        let value = coin::value(&payment);
        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS); 
        transfer::public_transfer(payment, game.admin);
        let magic = (value - MIN_SWORD_COST) / MIN_SWORD_COST;
        Sword {
            id: object::new(ctx),
            magic: math::min(magic, MAX_MAGIC),
            strength: 1,
            game_id: id(game)
        }
    }

    public fun create_armor(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Armor {
        // Create a sword, streight depends on payment amount
        let value = coin::value(&payment);
        assert!(value >= MIN_ARMOR_COST, EINSUFFICIENT_FUNDS); 
        transfer::public_transfer(payment, game.admin);
        let guard = (value - MIN_ARMOR_COST) / MIN_ARMOR_COST;
        Armor {
            id: object::new(ctx),
            guard: math::min(guard, MAX_GUARD),
            game_id: id(game)
        }
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment1: Coin<SUI>, payment2: Coin<SUI>, ctx: &mut TxContext
    ) {
        // call function create_armor
        let armor = create_armor(game, payment2, ctx);
        // call function create_sword
        let sword = create_sword(game, payment1, ctx);
        // call function create_hero
        let hero = create_hero(game, sword, armor, ctx);
        transfer::public_transfer(hero, tx_context::sender(ctx));
    }

    public fun create_hero(game: &GameInfo, sword: Sword, armor: Armor, ctx: &mut TxContext): Hero {
        // Create a new hero
        check_id(game, sword.game_id);
        Hero {
            id: object::new(ctx),
            hp: 100,
            mana: 100,
            level: 1,
            experience: 0,
            sword: option::some(sword),
            armor: option::some(armor),
            game_id: id(game)
        }
    }

    public entry fun send_potion(game: &GameInfo, payment: Coin<SUI>, player: address, ctx: &mut TxContext) {
        // send potion to hero, so that hero can healing
        // check_id(game, admin.game_id);
        let value = coin::value(&payment);
        let potency = value * 10;
        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS); 
        // admin.potions_created = admin.potions_created + 1;

        transfer::public_transfer(payment, game.admin);
        transfer::public_transfer(
            Potion { id: object::new(ctx), potency, game_id: id(game) },
            player
        );
    }

    public entry fun send_monster(game: &GameInfo, admin: &mut GameAdmin, hp: u64, strength: u64, player: address, ctx: &mut TxContext) {
        // send monster to hero to attacks
        check_id(game, admin.game_id);
        admin.monsters_created = admin.monsters_created + 1;
        transfer::transfer(
            Monster { id: object::new(ctx), hp, strength, game_id: id(game) },
            player
        );

    }

    //--- Game integrity / Links checks ---
    public fun check_id(game_info: &GameInfo, id: ID) {
        assert!(id(game_info) == id, ID_MISMATCH_ERR); // TODO: error code
    }
    public fun id(game_info: &GameInfo): ID {
        object::id(game_info)
    }

    // --- Testing function
    public fun assert_hero_strength(hero: &Hero, strength: u64) {
        assert!(hero_strength(hero) == strength, ASSERT_ERR);
    }

}
