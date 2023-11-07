module game_hero::hero_test {
    use sui::test_scenario;
    use game_hero::hero::{Self, GameInfo, GameAdmin, Hero, Monster};
    use game_hero::sea_hero::{Self, SeaHeroAdmin, SeaMonster, VBI_TOKEN};
    use game_hero::sea_hero_helper::{Self, HelpMeSlayThisMonster};
    use sui::coin::{Self, Coin};

    #[test]
    fun test_slay_monster() {
        // hoan thien function de test 1 kich ban

        let admin = @0xBABE;
        let player = @0xCAFE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        {
            hero::new_game(test_scenario::ctx(scenario));
        };

        // - tao hero
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin1 = coin::mint_for_testing(100, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - tao monster
        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;

            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);
            hero::send_monster(game_ref, &mut admin_cap, 30, 5, player, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // - slay
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: Monster = test_scenario::take_from_sender<Monster>(scenario);

            hero::attack(&game, &mut hero, monster, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, hero);
            // test_scenario::return_to_sender(scenario, mofnster);
        };

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_slay_sea_monster() {
        // hoan thien function de test 1 kich ban

        let admin = @0xBABE;
        let player = @0xCAFE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        {
            hero::new_game(test_scenario::ctx(scenario));
            sea_hero::new_game(test_scenario::ctx(scenario));
        };

        // - tao hero
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let coin1 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(&game, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - tao sea monster
        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::send_sea_monster(&mut admin_cap, 3, player, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // this will cause errors since the play didn't get any reward before slaying the monster
        // test_scenario::next_tx(scenario, player);
        // {
        //     let c: Coin<VBI_TOKEN> = test_scenario::take_from_sender<Coin<VBI_TOKEN>>(scenario);
        //     test_scenario::return_to_sender(scenario, c);
        // };

        // - slay
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            sea_hero::attack(&mut hero, monster, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, hero);
        };

        // check whether hero has received any VBI_TOKEN
        test_scenario::next_tx(scenario, player);
        {
            let c: Coin<VBI_TOKEN> = test_scenario::take_from_sender<Coin<VBI_TOKEN>>(scenario);
            test_scenario::return_to_sender(scenario, c);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_hero_helper_slay() {
        // hoan thien function de test 1 kich ban

        let admin = @0xBABE;
        let player = @0xCAFE;
        let player2 = @0xDADE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        {
            hero::new_game(test_scenario::ctx(scenario));
            sea_hero::new_game(test_scenario::ctx(scenario));
        };

        // - tao hero
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let coin1 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(&game, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - tao hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let coin1 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(&game, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - tao sea monster
        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::send_sea_monster(&mut admin_cap, 3, player, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        // - create help
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            sea_hero_helper::create_help(monster, 2, player2, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
        };

        // - slay
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let wrapper: HelpMeSlayThisMonster = test_scenario::take_from_sender<HelpMeSlayThisMonster>(scenario);

            sea_hero_helper::attack(&hero, wrapper, test_scenario::ctx(scenario));

            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, hero);
        };

        // - check reward of both heroes/players
        test_scenario::next_tx(scenario, player);
        {
            let c: Coin<VBI_TOKEN> = test_scenario::take_from_sender<Coin<VBI_TOKEN>>(scenario);
            test_scenario::return_to_sender(scenario, c);
        };

        test_scenario::next_tx(scenario, player2);
        {
            let c: Coin<VBI_TOKEN> = test_scenario::take_from_sender<Coin<VBI_TOKEN>>(scenario);
            test_scenario::return_to_sender(scenario, c);
        };

        test_scenario::end(scenario_val);

    }

    #[test]
    fun test_hero_attack_hero() {
        // hoan thien function de test 1 kich ban
        // - tao hero
        let admin = @0xBABE;
        let player = @0xCAFE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        {
            hero::new_game(test_scenario::ctx(scenario));
        };

        // - tao hero
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin1 = coin::mint_for_testing(100, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // - tao hero 2

        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin1 = coin::mint_for_testing(200, test_scenario::ctx(scenario));
            let coin2 = coin::mint_for_testing(2000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin1, coin2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // - slay 1 vs 2
        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let hero1: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let hero2: Hero = test_scenario::take_from_sender<Hero>(scenario);
            hero::p2p_play(&game, &mut hero1, &mut hero2, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
            test_scenario::return_to_sender(scenario, hero1);
            test_scenario::return_to_sender(scenario, hero2);
        };

        // check who will win
        test_scenario::end(scenario_val);
    }
}
