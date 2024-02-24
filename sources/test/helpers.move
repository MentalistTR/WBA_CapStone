#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{TransferPolicy};
    use sui::test_utils::{assert_eq};
    use sui::object::{ID};
    
    use std::string::{Self};
    // use std::option::{Self};
    // use std::debug;
    use std::vector;

    use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes, AssetsTypePublisher, test_init};
    use notary::assets::{Self, Asset};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;

    public fun helper_create_asset(scenario: &mut Scenario, sender: address) {
        // create a Asset object
        next_tx(scenario, sender);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let price: u64 = 10000;
            let type = string::utf8(b"House");

            at::create_asset(
                type,
                price,
        &mut listed_shared,
         &mut kiosk,
           ts::ctx(scenario));

            ts::return_shared(kiosk);
            ts::return_shared(listed_shared);
        };
    }
    
    public fun helper_add_types(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
     
            let type1 = string::utf8(b"House");
            let type2 = string::utf8(b"Car");
            let type3 = string::utf8(b"Shop");
            let type4 = string::utf8(b"Land");

            at::create_type(&admin_cap, &mut listed_shared, type1);
            at::create_type(&admin_cap, &mut listed_shared, type2);
            at::create_type(&admin_cap, &mut listed_shared, type3);
            at::create_type(&admin_cap, &mut listed_shared, type4);

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(listed_shared);
        };
    }
    
    public fun helper_new_policy(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let publisher_share = ts::take_shared<AssetsTypePublisher>(scenario);
            //let publisher = at::get_publisher(&publisher_share);

            at::new_policy(&admin_cap, &publisher_share, ts::ctx(scenario));

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(publisher_share);
        };
    }

    public fun init_test_helper() : ts::Scenario{
       let owner: address = @0xA;
       let scenario_val = ts::begin(owner);
       let scenario = &mut scenario_val;
 
       {
            test_init(ts::ctx(scenario));
       };
       {
            return_init_lira(ts::ctx(scenario));
       };
       scenario_val
}

}
