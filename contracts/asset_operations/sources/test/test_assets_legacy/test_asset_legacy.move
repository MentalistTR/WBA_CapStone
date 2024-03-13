#[test_only]
module notary::test_asset_legacy {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk,};
    use sui::sui::SUI;
    use sui::coin::{Self, mint_for_testing, from_balance, Coin, CoinMetadata};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    
    use std::string::{Self};
    use std::vector::{Self};
    use std::debug;

    use notary::assets::{Wrapper};
    use notary::helpers::{Self, init_test_helper, helper_new_policy};
    use notary::assets_type::{Self as at, AdminCap, ListedTypes};
    use notary::lira::{LIRA};
    use notary::assets_legacy::{Self as al, Legacy};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;
    const TEST_ADDRESS4: address = @0xE; 
    const TEST_ADDRESS5: address = @0xF;


    #[test]
    #[expected_failure(abort_code = al::ERROR_INVALID_TIME)]
    public fun test_early_distribute() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

         // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };
        // set the kiosk1_data
        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
        let kiosk1_ = ts::created(&kiosk1_data);
        let kiosk1_id = vector::borrow(&kiosk1_, 0);

        // create an legacy share object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let start_time = clock::create_for_testing(ts::ctx(scenario));
            // set the legacy remaining 3 months
            let remaining: u64 = 3;

            al::new_legacy(remaining, &start_time, ts::ctx(scenario));

            clock::share_for_testing(start_time);
        };
        // keep clock data for using later
        let clock_data = next_tx(scenario, TEST_ADDRESS1);
        //debug::print(&clock_data);
        let clock1_ = ts::shared(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 1);

        // 89 days passed so we are expecting failure
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let legacy = ts::take_shared<Legacy>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let clock = ts::take_shared_by_id<Clock>(scenario, *clock1_id);
            
            clock::increment_for_testing(&mut clock, (86400 * 89));

            al::distribute<SUI>(&admin_cap, &mut legacy, &mut kiosk, &clock, ts::ctx(scenario));

            ts::return_shared(clock);
            ts::return_shared(legacy);
            ts::return_to_sender(scenario,admin_cap);
            ts::return_shared(kiosk);
        };
        ts::end(scenario_test);
    }
    
    #[test]
    public fun test_deposit_legacy_add_heirs() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

         // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };
        // set the kiosk1_data
        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
        let kiosk1_ = ts::created(&kiosk1_data);
        let kiosk1_id = vector::borrow(&kiosk1_, 0);

        // create an legacy share object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let start_time = clock::create_for_testing(ts::ctx(scenario));
            // set the legacy remaining 3 months
            let remaining: u64 = 3;

            al::new_legacy(remaining, &start_time, ts::ctx(scenario));

            clock::share_for_testing(start_time);
        };
        // keep clock data for using later
        let clock_data = next_tx(scenario, TEST_ADDRESS1);
        //debug::print(&clock_data);
        let clock1_ = ts::shared(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 1);

        // deposit 10000 LIRA for legacy
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let lira_metadata = ts::take_immutable<CoinMetadata<LIRA>>(scenario);
            let deposit = mint_for_testing<LIRA>(10000, ts::ctx(scenario));

            al::deposit_legacy<LIRA>(&mut kiosk, deposit, &lira_metadata);

            let coin_name = at::test_get_coin_name(&kiosk, 0);
            let coin_amount = at::test_get_coin_amount<LIRA>(&kiosk, coin_name);

            assert_eq(coin_amount, 10000);

            ts::return_immutable(lira_metadata);
            ts::return_shared(kiosk);
        };
        // ADD 4 heirs both have %25
        helpers::add_heirs(scenario, 2500, 2500, 2500, 2500);
        // add new heirs
        next_tx(scenario, TEST_ADDRESS1);
        {
            let legacy = ts::take_shared<Legacy>(scenario);
    
            let heirs_address  = vector::empty();   
            let heirs_percentage = vector::empty(); 

            vector::push_back(&mut heirs_address, TEST_ADDRESS2);
            vector::push_back(&mut heirs_address, TEST_ADDRESS3); 

            vector::push_back(&mut heirs_percentage, 5000);
            vector::push_back(&mut heirs_percentage, 5000);
 
            al::new_heirs(&mut legacy, heirs_address, heirs_percentage, ts::ctx(scenario));  
    
            ts::return_shared(legacy);  
        };

        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = al::ERROR_INVALID_ARRAY_LENGTH)]
    public fun test_heirs() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

         // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };
        // set the kiosk1_data
        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
        let kiosk1_ = ts::created(&kiosk1_data);
        let kiosk1_id = vector::borrow(&kiosk1_, 0);

        // create an legacy share object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let start_time = clock::create_for_testing(ts::ctx(scenario));
            // set the legacy remaining 3 months
            let remaining: u64 = 3;

            al::new_legacy(remaining, &start_time, ts::ctx(scenario));

            clock::share_for_testing(start_time);
        };
        // ADD 4 heirs both have %25
        helpers::add_heirs(scenario, 2500, 2500, 2500, 2500);

        // add new heirs
        next_tx(scenario, TEST_ADDRESS1);
        {
            let legacy = ts::take_shared<Legacy>(scenario);
    
            let heirs_address  = vector::empty();   
            let heirs_percentage = vector::empty(); 

            vector::push_back(&mut heirs_address, TEST_ADDRESS2);
            vector::push_back(&mut heirs_address, TEST_ADDRESS3); 

            vector::push_back(&mut heirs_percentage, 5000);
            vector::push_back(&mut heirs_percentage, 5000);
            vector::push_back(&mut heirs_percentage, 5000);
 
            al::new_heirs(&mut legacy, heirs_address, heirs_percentage, ts::ctx(scenario));  
    
            ts::return_shared(legacy);  
        };

        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = al::ERROR_INVALID_PERCENTAGE_SUM)]
    public fun test_heirs_percentage() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

         // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };
        // set the kiosk1_data
        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
        let kiosk1_ = ts::created(&kiosk1_data);
        let kiosk1_id = vector::borrow(&kiosk1_, 0);

        // create an legacy share object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let start_time = clock::create_for_testing(ts::ctx(scenario));
            // set the legacy remaining 3 months
            let remaining: u64 = 3;

            al::new_legacy(remaining, &start_time, ts::ctx(scenario));

            clock::share_for_testing(start_time);
        };
        // ADD 4 heirs both have %25
        helpers::add_heirs(scenario, 2500, 2500, 2500, 2500);
        
        // add new heirs
        next_tx(scenario, TEST_ADDRESS1);
        {
            let legacy = ts::take_shared<Legacy>(scenario);
    
            let heirs_address  = vector::empty();   
            let heirs_percentage = vector::empty(); 

            vector::push_back(&mut heirs_address, TEST_ADDRESS2);
            vector::push_back(&mut heirs_address, TEST_ADDRESS3); 

            vector::push_back(&mut heirs_percentage, 5000);
            vector::push_back(&mut heirs_percentage, 4500);
 
            al::new_heirs(&mut legacy, heirs_address, heirs_percentage, ts::ctx(scenario));  
    
            ts::return_shared(legacy);  
        };

        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = al::ERROR_YOU_ARE_NOT_HEIR)]
    public fun test_distribute() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

         // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };
        // set the kiosk1_data
        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
        let kiosk1_ = ts::created(&kiosk1_data);
        let kiosk1_id = vector::borrow(&kiosk1_, 0);

        // create an legacy share object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let start_time = clock::create_for_testing(ts::ctx(scenario));
            // set the legacy remaining 3 months
            let remaining: u64 = 3;

            al::new_legacy(remaining, &start_time, ts::ctx(scenario));

            clock::share_for_testing(start_time);
        };
        // keep clock data for using later
        let clock_data = next_tx(scenario, TEST_ADDRESS1);
        let clock1_ = ts::shared(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 1);

        // deposit 10000 LIRA for legacy
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let lira_metadata = ts::take_immutable<CoinMetadata<LIRA>>(scenario);
            let deposit = mint_for_testing<LIRA>(10000, ts::ctx(scenario));

            al::deposit_legacy<LIRA>(&mut kiosk, deposit, &lira_metadata);

            let coin_name = at::test_get_coin_name(&kiosk, 0);
            let coin_amount = at::test_get_coin_amount<LIRA>(&kiosk, coin_name);

            assert_eq(coin_amount, 10000);

            ts::return_immutable(lira_metadata);
            ts::return_shared(kiosk);
        };
        // deposit 10000 SUI for legacy
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let deposit = mint_for_testing<SUI>(10000, ts::ctx(scenario));

            al::deposit_legacy_sui(&mut kiosk, deposit);

            let coin_name = at::test_get_coin_name(&kiosk, 0);
            let coin_amount = at::test_get_coin_amount<LIRA>(&kiosk, coin_name);

            assert_eq(coin_amount, 10000);

            ts::return_shared(kiosk);
        };
        // ADD 4 heirs both have %25
        helpers::add_heirs(scenario, 2500, 2500, 2500, 2500);
        // increment current time 91 days and distribute legacy
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let legacy = ts::take_shared<Legacy>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let clock = ts::take_shared_by_id<Clock>(scenario, *clock1_id);
            clock::increment_for_testing(&mut clock, (86400 * 91));

            al::distribute<LIRA>(
                &admin_cap,
                &mut legacy,
                &mut kiosk,
                &clock,
                ts::ctx(scenario)
            );

            let coin_name = string::utf8(b"Tr Lira");

            let amount1 = al::test_get_heir_balance<LIRA>(&legacy, TEST_ADDRESS2, coin_name);
            assert_eq(amount1, 2500);

            let amount2 = al::test_get_heir_balance<LIRA>(&legacy, TEST_ADDRESS3, coin_name);
            assert_eq(amount1, 2500);

            let amount3 = al::test_get_heir_balance<LIRA>(&legacy, TEST_ADDRESS4, coin_name);
            assert_eq(amount3, 2500);

            let amount4 = al::test_get_heir_balance<LIRA>(&legacy, TEST_ADDRESS5, coin_name);
            assert_eq(amount4, 2500);

            // legacy should be zero now
            let coin_amount = at::test_get_coin_amount<LIRA>(&kiosk, coin_name);
            assert_eq(coin_amount, 0);

            ts::return_shared(clock);
            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(legacy);  
        };
        // Distribute SUI to heirs
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let legacy = ts::take_shared<Legacy>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let clock = ts::take_shared_by_id<Clock>(scenario, *clock1_id);
            //clock::increment_for_testing(&mut clock, (86400 * 31));

            al::distribute<SUI>(
                &admin_cap,
                &mut legacy,
                &mut kiosk,
                &clock,
                ts::ctx(scenario)
            );

            let coin_name = string::utf8(b"sui");

            let amount1 = al::test_get_heir_balance<SUI>(&legacy, TEST_ADDRESS2, coin_name);
            assert_eq(amount1, 2500);

            let amount2 = al::test_get_heir_balance<SUI>(&legacy, TEST_ADDRESS3, coin_name);
            assert_eq(amount1, 2500);

            let amount3 = al::test_get_heir_balance<SUI>(&legacy, TEST_ADDRESS4, coin_name);
            assert_eq(amount3, 2500);

            let amount4 = al::test_get_heir_balance<SUI>(&legacy, TEST_ADDRESS5, coin_name);
            assert_eq(amount4, 2500);

            // legacy should be zero now
            let coin_amount = at::test_get_coin_amount<SUI>(&kiosk, coin_name);
            assert_eq(coin_amount, 0);

            ts::return_shared(clock);
            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(legacy);  
        };
        // user2 withdraw his legacy
        next_tx(scenario, TEST_ADDRESS2);
        {
            let legacy = ts::take_shared<Legacy>(scenario);
            let coin_name = string::utf8(b"Tr Lira");

            let amount =  al::withdraw<LIRA>(&mut legacy, coin_name, ts::ctx(scenario));
            let withdraw = from_balance<LIRA>(amount, ts::ctx(scenario));

            transfer::public_transfer(withdraw, TEST_ADDRESS2);

            ts::return_shared(legacy);  
        };
        // check the user balance
        next_tx(scenario, TEST_ADDRESS2);
        {
            let balance = ts::take_from_sender<Coin<LIRA>>(scenario);

            assert_eq(coin::value(&balance), 2500);

            ts::return_to_sender(scenario, balance);
        };
        // user1 withdraw his legacy and we are expecting error because he is not heir.
        next_tx(scenario, TEST_ADDRESS1);
        {
            let legacy = ts::take_shared<Legacy>(scenario);
            let coin_name = string::utf8(b"Tr Lira");

            let amount =  al::withdraw<LIRA>(&mut legacy, coin_name, ts::ctx(scenario));
            let withdraw = from_balance<LIRA>(amount, ts::ctx(scenario));

            transfer::public_transfer(withdraw, TEST_ADDRESS2);

            ts::return_shared(legacy);  
        };

        ts::end(scenario_test);
    }
}
