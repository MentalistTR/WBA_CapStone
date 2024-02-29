#[test_only]
module notary::test_renting {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::package::{Publisher};
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::object;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing};
    use sui::coin::{Self, Coin};
    use sui::table;
    use sui::clock::{Self, Clock};
    
    use std::string::{Self, String};
    use std::vector::{Self};
    use std::debug;
    use std::option;

    use notary::assets::{Self, Asset};
    use notary::helpers::{init_test_helper, helper_new_policy};
    use notary::assets_type::{Self as at, AdminCap, ListedTypes};
    use notary::assets_renting::{Self as ar, Contracts};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    #[expected_failure(abort_code = ar::ERROR_NOT_KIOSK_OWNER)]
    public fun test_list() {
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
     
        // TEST_ADDRESS2 had created an kiosk
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));

            ts::return_shared(shared);
        };
        // set the kiosk2_data
        let kiosk2_data = next_tx(scenario, TEST_ADDRESS2);
        let kiosk2_ = ts::created(&kiosk2_data);
        let kiosk2_id = vector::borrow(&kiosk2_, 0); 
       
        // admin should create an transferpolicy
        helper_new_policy(scenario);

        // create an asset 1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

            let price: u64 = 10000;
            let type = string::utf8(b"House");

            at::create_asset(
        &mut listed_shared,
         &mut kiosk1_shared,
                              type,
           ts::ctx(scenario));

           let asset_id = object::last_created(ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), false);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(listed_shared);
        };
        // define the asset_id1
        let asset_id1 = object::last_created(ts::ctx(scenario));

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            at::approve(
                &admin_cap,
                &listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                TEST_ADDRESS1
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
            ts::return_to_sender(scenario, admin_cap);
        };
        // User1 listing asset1 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            ar::list_with_purchase_cap(
                &mut listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                1000,
                TEST_ADDRESS2,
                ts::ctx(scenario)
            );
            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
        };
        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = ar::ERROR_INVALID_PRICE)]
    public fun test_list_rent() {
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
     
        // TEST_ADDRESS2 had created an kiosk
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));

            ts::return_shared(shared);
        };
        // set the kiosk2_data
        let kiosk2_data = next_tx(scenario, TEST_ADDRESS2);
        let kiosk2_ = ts::created(&kiosk2_data);
        let kiosk2_id = vector::borrow(&kiosk2_, 0); 
       
        // admin should create an transferpolicy
        helper_new_policy(scenario);

        // create an asset 1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

            let price: u64 = 10000;
            let type = string::utf8(b"House");

            at::create_asset(
        &mut listed_shared,
         &mut kiosk1_shared,
                              type,
           ts::ctx(scenario));

           let asset_id = object::last_created(ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), false);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(listed_shared);
        };
        // define the asset_id1
        let asset_id1 = object::last_created(ts::ctx(scenario));

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            at::approve(
                &admin_cap,
                &listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                TEST_ADDRESS1
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
            ts::return_to_sender(scenario, admin_cap);
        };
        // User1 listing asset1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            ar::list_with_purchase_cap(
                &mut listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                1000,
                TEST_ADDRESS2,
                ts::ctx(scenario)
            );
            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
        };
         // User2 renting the asset 1
        next_tx(scenario, TEST_ADDRESS2);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let contracts = ts::take_shared<Contracts>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let purch_cap = ts::take_from_sender<PurchaseCap<Asset>>(scenario);
            let payment_ = mint_for_testing<SUI>(1500, ts::ctx(scenario));
            let rental_period = 12;
            let start_time = clock::create_for_testing(ts::ctx(scenario));

            ar::rent(
                &mut contracts,
                &listed_shared,
                &mut kiosk1_shared,
                &mut kiosk2_shared,
                &policy,
                purch_cap,
                asset_id1,
                payment_,
                rental_period,
                &start_time,
                ts::ctx(scenario)
            );

            clock::share_for_testing(start_time);            
            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(contracts);
            ts::return_shared(listed_shared);
        };
        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = ar::ERROR_ASSET_IN_RENTING)]
    public fun test_list_renting() {
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
     
        // TEST_ADDRESS2 had created an kiosk
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));

            ts::return_shared(shared);
        };
        // set the kiosk2_data
        let kiosk2_data = next_tx(scenario, TEST_ADDRESS2);
        let kiosk2_ = ts::created(&kiosk2_data);
        let kiosk2_id = vector::borrow(&kiosk2_, 0); 
       
        // admin should create an transferpolicy
        helper_new_policy(scenario);

        // create an asset 1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

            let price: u64 = 10000;
            let type = string::utf8(b"House");

            at::create_asset(
        &mut listed_shared,
         &mut kiosk1_shared,
                              type,
           ts::ctx(scenario));

           let asset_id = object::last_created(ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), false);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(listed_shared);
        };
        // define the asset_id1
        let asset_id1 = object::last_created(ts::ctx(scenario));

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            at::approve(
                &admin_cap,
                &listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                TEST_ADDRESS1
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
            ts::return_to_sender(scenario, admin_cap);
        };
        // User1 listing asset1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            ar::list_with_purchase_cap(
                &mut listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                1000,
                TEST_ADDRESS2,
                ts::ctx(scenario)
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
        };
        // User2 renting the asset 1
        next_tx(scenario, TEST_ADDRESS2);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let contracts = ts::take_shared<Contracts>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let purch_cap = ts::take_from_sender<PurchaseCap<Asset>>(scenario);
            let payment_ = mint_for_testing<SUI>(2000, ts::ctx(scenario));
            let rental_period = 12;
            let start_time = clock::create_for_testing(ts::ctx(scenario));

            ar::rent(
                &mut contracts,
                &listed_shared,
                &mut kiosk1_shared,
                &mut kiosk2_shared,
                &policy,
                purch_cap,
                asset_id1,
                payment_,
                rental_period,
                &start_time,
                ts::ctx(scenario)
            );

            clock::share_for_testing(start_time);            
            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(contracts);
            ts::return_shared(listed_shared);
        };
        let clock_data = next_tx(scenario, TEST_ADDRESS2);
        let clock1_ = ts::created(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 0); 
        // 
        next_tx(scenario, TEST_ADDRESS1); 
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let contracts = ts::take_shared<Contracts>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let payment_ = mint_for_testing<SUI>(1, ts::ctx(scenario));
            let clock= ts::take_shared_by_id<Clock>(scenario, *clock1_id);
            // increment the current time 30 days
            clock::increment_for_testing(&mut clock, (86400 * 29));

            ar::get_asset(
                &mut listed_shared,
                &mut contracts,
                &mut kiosk1_shared,
                &mut kiosk2_shared,
                asset_id1,
                &policy,
                payment_,
                &clock,
                ts::ctx(scenario)
            );

            ts::return_shared(clock);
            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(contracts);
            ts::return_shared(listed_shared);
        };
        ts::end(scenario_test);
    }
    // scenario >    1-) user 2 renting,
    // scenario >    2-)  29 days passed, 
    // scenario >    3-) 2. month renting payed
    // scenario >    4-) In 59. Day owner try to back asset 

    #[test]
    #[expected_failure(abort_code = ar::ERROR_ASSET_IN_RENTING)]
    public fun test_list_rent_get_asset() {
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
     
        // TEST_ADDRESS2 had created an kiosk
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));

            ts::return_shared(shared);
        };
        // set the kiosk2_data
        let kiosk2_data = next_tx(scenario, TEST_ADDRESS2);
        let kiosk2_ = ts::created(&kiosk2_data);
        let kiosk2_id = vector::borrow(&kiosk2_, 0); 
       
        // admin should create an transferpolicy
        helper_new_policy(scenario);

        // create an asset 1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

            let price: u64 = 10000;
            let type = string::utf8(b"House");

            at::create_asset(
        &mut listed_shared,
         &mut kiosk1_shared,
                              type,
           ts::ctx(scenario));

           let asset_id = object::last_created(ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), false);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(listed_shared);
        };
        // define the asset_id1
        let asset_id1 = object::last_created(ts::ctx(scenario));

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);

            at::approve(
                &admin_cap,
                &listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                TEST_ADDRESS1
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
            ts::return_to_sender(scenario, admin_cap);
        };
        // User1 listing asset1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            ar::list_with_purchase_cap(
                &mut listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                1000,
                TEST_ADDRESS2,
                ts::ctx(scenario)
            );

            ts::return_shared(listed_shared);
            ts::return_shared(kiosk1_shared);
        };
        // User2 renting the asset 1
        next_tx(scenario, TEST_ADDRESS2);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let contracts = ts::take_shared<Contracts>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let purch_cap = ts::take_from_sender<PurchaseCap<Asset>>(scenario);
            let payment_ = mint_for_testing<SUI>(2000, ts::ctx(scenario));
            let rental_period = 12;
            let start_time = clock::create_for_testing(ts::ctx(scenario));

            ar::rent(
                &mut contracts,
                &listed_shared,
                &mut kiosk1_shared,
                &mut kiosk2_shared,
                &policy,
                purch_cap,
                asset_id1,
                payment_,
                rental_period,
                &start_time,
                ts::ctx(scenario)
            );

            clock::share_for_testing(start_time);            
            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(contracts);
            ts::return_shared(listed_shared);
        };

        let clock_data = next_tx(scenario, TEST_ADDRESS2);
        let clock1_ = ts::created(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 0); 

        // time has been increased 29 days. 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let contracts = ts::take_shared<Contracts>(scenario);
            let payment_ = mint_for_testing<SUI>(1000, ts::ctx(scenario));
            let clock= ts::take_shared_by_id<Clock>(scenario, *clock1_id);
    
            // increment the current time 30 days
            clock::increment_for_testing(&mut clock, (86400 * 29));
            
            ar::pay_monthly_rent(&mut contracts, payment_, asset_id1, ts::ctx(scenario));

            ts::return_shared(clock);
            ts::return_shared(contracts);
        };
        // Owner trying to get his asset 
        next_tx(scenario, TEST_ADDRESS1); 
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let contracts = ts::take_shared<Contracts>(scenario);
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let payment_ = mint_for_testing<SUI>(1, ts::ctx(scenario));
            let clock= ts::take_shared_by_id<Clock>(scenario, *clock1_id);
            // increment the current time 30 days
            clock::increment_for_testing(&mut clock, (86400 * 30));

            ar::get_asset(
                &mut listed_shared,
                &mut contracts,
                &mut kiosk1_shared,
                &mut kiosk2_shared,
                asset_id1,
                &policy,
                payment_,
                &clock,
                ts::ctx(scenario)
            );

            ts::return_shared(clock);
            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(contracts);
            ts::return_shared(listed_shared);
        };



        ts::end(scenario_test);
    }

 




}
