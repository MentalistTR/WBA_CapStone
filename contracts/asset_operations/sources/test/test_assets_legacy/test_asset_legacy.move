#[test_only]
module notary::test_asset_legacy {
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk, PurchaseCap};
    use sui::transfer_policy::{TransferPolicy, TransferPolicyCap};
    use sui::object::{Self};
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing, CoinMetadata};
    use sui::clock::{Self, Clock};
    
    use std::string::{Self};
    use std::vector::{Self};
    use std::debug;

    use notary::assets::{Wrapper};
    use notary::helpers::{init_test_helper, helper_new_policy};
    use notary::assets_type::{Self as at, AdminCap, ListedTypes};
    use notary::assets_renting::{Self as ar, Contracts};
    use notary::lira::{LIRA};
    use notary::assets_legacy::{Self as al, Legacy};

    use rules::loan_duration::{Self as ld};
    use rules::time_duration::{Self as td};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

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

            al::new_legacy(ts::ctx(scenario), &start_time);

            clock::share_for_testing(start_time);
        };
        // keep clock data for using later
        let clock_data = next_tx(scenario, TEST_ADDRESS1);
        //debug::print(&clock_data);
        let clock1_ = ts::shared(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 1);

        // 29 days passed so we are expecting failure
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let legacy = ts::take_shared<Legacy>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let clock = clock::create_for_testing(ts::ctx(scenario));
            
            clock::increment_for_testing(&mut clock, (86400 * 29));

            al::distribute<SUI>(&admin_cap, &mut legacy, &mut kiosk, &clock, ts::ctx(scenario));

            ts::return_shared(clock);
            ts::return_shared(legacy);
            ts::return_to_sender(scenario,admin_cap);
            ts::return_shared(kiosk);
        };
        ts::end(scenario_test);
    }

    #[test]
    public fun test_deposit_legacy() {
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

            al::new_legacy(ts::ctx(scenario), &start_time);

            clock::share_for_testing(start_time);
        };
        // keep clock data for using later
        let clock_data = next_tx(scenario, TEST_ADDRESS1);
        //debug::print(&clock_data);
        let clock1_ = ts::shared(&clock_data);
        let clock1_id = vector::borrow(&clock1_, 1);

        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let lira_metadata = ts::take_immutable<CoinMetadata<LIRA>>(scenario);
            let deposit = mint_for_testing<LIRA>(10000, ts::ctx(scenario));

            al::deposit_legacy<LIRA>(&mut kiosk, deposit, &lira_metadata);

            ts::return_immutable(lira_metadata);
            ts::return_shared(kiosk);
        };




   
        ts::end(scenario_test);
    }







}