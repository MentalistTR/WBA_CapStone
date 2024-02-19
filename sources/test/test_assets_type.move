#[test_only]
module notary::test_assets_type {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::package::{Publisher};
    use sui::transfer_policy::{TransferPolicy};

    use std::string::{Self};

    use notary::assets::{Self, Asset};

    use notary::helpers::{init_test_helper, helper_add_types};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes, Rule, NotaryKioskExtWitness};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_rules() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create types
        helper_add_types(scenario);
  
        ts::end(scenario_test);
    }

    #[test]
    #[expected_failure(abort_code = at::ERROR_INVALID_TYPE)]
    public fun test_rules_fail() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create types such as House, Car, Land, Shop
        helper_add_types(scenario);
        // Admin trying to create same types so we are expecting error
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let shared = ts::take_shared<ListedTypes>(scenario);
            let type = string::utf8(b"House");

            at::create_type(&admin_cap, &mut shared, type);

            ts::return_shared(shared);
            ts::return_to_sender(scenario, admin_cap);
        };
         ts::end(scenario_test);
    }
    #[test]
    public fun test_create_kiosk() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create an kiosk
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let publisher = ts::take_from_sender<Publisher>(scenario);

            at::create_kiosk(&admin_cap, &publisher, ts::ctx(scenario));

            ts::return_to_sender(scenario, admin_cap);
            ts::return_to_sender(scenario, publisher);
        };
        // add extensions to kiosk 
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let kiosk_cap= ts::take_from_sender<KioskOwnerCap>(scenario);
            let permission : u128 = 01;

            at::add_extensions(&admin_cap, &mut kiosk, &kiosk_cap, permission, ts::ctx(scenario));

            ts::return_to_sender(scenario, kiosk_cap);
            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, admin_cap);
        };
        next_tx(scenario, TEST_ADDRESS1);
        {
            let type = string::utf8(b"House");
            let price: u64 = 10000;
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_asset(type, price, &mut shared, &policy, &mut kiosk, ts::ctx(scenario));
            
            ts::return_shared(policy);
            ts::return_shared(kiosk);
            ts::return_shared(shared);
        };
        next_tx(scenario, ADMIN);
        {   
            let shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let kiosk_cap= ts::take_from_sender<KioskOwnerCap>(scenario);
            let asset_id = at::get_id(&shared);

            at::approve(&mut kiosk, &kiosk_cap, asset_id);

            ts::return_to_sender(scenario, kiosk_cap);
            ts::return_shared(kiosk);
            ts::return_shared(shared);
        };

        
        ts::end(scenario_test);

    }




    


}