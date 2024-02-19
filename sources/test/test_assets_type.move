#[test_only]
module notary::test_assets_type {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Kiosk, KioskOwnerCap};

    use std::string::{Self};

    use notary::assets::{Self, Asset};

    use notary::helpers::{init_test_helper, helper_add_types};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes, Rule};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    struct Ext has drop {}

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

            at::create_kiosk(&admin_cap, ts::ctx(scenario));

            ts::return_to_sender(scenario, admin_cap);
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


        ts::end(scenario_test);

    }




    


}