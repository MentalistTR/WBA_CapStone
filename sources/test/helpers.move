#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{TransferPolicy};
    use sui::test_utils::{assert_eq};


    use std::string::{Self};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes, test_init};
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

    public fun  helper_add_extensions(scenario: &mut Scenario, sender: address, permissons: u128) {
        next_tx(scenario, sender);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let kiosk_cap= ts::take_from_sender<KioskOwnerCap>(scenario);
    
            at::add_extensions(&mut kiosk, &kiosk_cap, permissons, ts::ctx(scenario));

            ts::return_to_sender(scenario, kiosk_cap);
            ts::return_shared(kiosk);
        };
    }

    public fun helper_approve(scenario: &mut Scenario, index: u64) {
     next_tx(scenario, ADMIN);
        {   
            let shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let id_ = at::get_id(&shared, index);

            assert_eq(kiosk::has_item(&kiosk, id_), false);

            at::approve(&admin_cap,&mut kiosk, &policy, id_);

            assert_eq(kiosk::has_item(&kiosk, id_), true);
            assert_eq(kiosk::is_locked(&kiosk, id_), false);
            assert_eq(kiosk::is_listed(&kiosk, id_), false);

            ts::return_shared(policy);
            ts::return_shared(kiosk);
            ts::return_shared(shared);
            ts::return_to_sender(scenario, admin_cap);

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
