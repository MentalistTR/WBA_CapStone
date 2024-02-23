#[test_only]
module notary::test_assets_type {
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
    

    use std::string::{Self, String};
    use std::vector::{Self};
    use std::debug;
    use std::option;

    use notary::assets::{Self, Asset};

    use notary::helpers::{init_test_helper, helper_add_types, helper_add_extensions, helper_create_asset,
    helper_approve};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes};
    
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
    public fun test_kiosk_place_list() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            at::create_kiosk(ts::ctx(scenario));
        };
        // add extensions to place any asset
        helper_add_extensions(scenario, TEST_ADDRESS1, 01);
        // create an asset 1 
        helper_create_asset(scenario, TEST_ADDRESS1);
        // create an asset 2
        helper_create_asset(scenario, TEST_ADDRESS1);
        // admin should approve Asset1 
        helper_approve(scenario, 0);
        // admin should approve Asset2
        helper_approve(scenario, 1);
        // TEST_ADDRESS1 Listing the asset 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let id_ = at::get_id(&shared, 1);

            let taken_nft = kiosk::take<Asset>(&mut kiosk, &kiosk_cap, id_);
            assert_eq(kiosk::has_item(&kiosk, id_), false);
            
            kiosk::lock(&mut kiosk, &kiosk_cap, &policy, taken_nft);
            
            assert_eq(kiosk::has_item(&kiosk, id_), true);
            assert_eq(kiosk::is_locked(&kiosk, id_), true);
            assert_eq(kiosk::is_listed(&kiosk, id_), false);            
            
            kiosk::list<Asset>(&mut kiosk, &kiosk_cap, id_, 100);
            assert_eq(kiosk::is_listed(&kiosk, id_), true);

            kiosk::delist<Asset>(&mut kiosk, &kiosk_cap, id_);

            assert_eq(kiosk::is_listed(&kiosk, id_), false);

            kiosk::list<Asset>(&mut kiosk, &kiosk_cap, id_, 100);

            assert_eq(kiosk::is_listed(&kiosk, id_), true);
            assert_eq(kiosk::is_listed_exclusively(&kiosk, id_), false);

            ts::return_shared(policy);
            ts::return_shared(kiosk);
            ts::return_shared(shared);
            ts::return_to_sender(scenario, kiosk_cap);
        };
        // TEST_ADDRESS2 is going to buy asset from address 1
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let id_ = at::get_id(&shared, 1);

            assert_eq(kiosk::has_item(&kiosk, id_), true);

            let (nft, request) = kiosk::purchase<Asset>(
                &mut kiosk,
                id_,
                mint_for_testing(100, ts::ctx(scenario))
            );

            assert_eq(kiosk::has_item(&kiosk, id_), false);
            policy:: confirm_request(&policy, request);

            transfer::public_transfer(nft, TEST_ADDRESS2);

            ts::return_shared(policy);
            ts::return_shared(kiosk);
            ts::return_shared(shared);
        };
        // withdraw the profits from kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let kiosk_cap = ts::take_from_sender<KioskOwnerCap>(scenario);

            assert_eq(kiosk::profits_amount(&kiosk), 100);

            let profit = kiosk::withdraw(
                &mut kiosk,
                &kiosk_cap,
                option::some(100),
                ts::ctx(scenario)
                );
            assert_eq(kiosk::profits_amount(&kiosk), 0);

            transfer::public_transfer(profit, TEST_ADDRESS1);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, kiosk_cap);
        };
        // check the Owner of kiosk balance 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let user_balance = ts::take_from_sender<Coin<SUI>>(scenario);
            assert_eq(coin::value(&user_balance), 100);
            ts::return_to_sender(scenario, user_balance);
        };
        ts::end(scenario_test);
    }
    #[test]
    public fun test_kiosk_list_by_purchase() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            at::create_kiosk(ts::ctx(scenario));
        };
        // add extensions to place any asset
        helper_add_extensions(scenario, TEST_ADDRESS1, 01);
        // create an asset 1 
        helper_create_asset(scenario, TEST_ADDRESS1);
        //create an asset 2
        helper_create_asset(scenario, TEST_ADDRESS1);
        // admin should approve Asset1 
        helper_approve(scenario, 0);
        // admin should approve Asset2
        helper_approve(scenario, 1);

        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let id_ = at::get_id(&shared, 0);
            let min_price: u64 = 10000;

            assert_eq(kiosk::has_item(&kiosk, id_), true);

            assert_eq(kiosk::has_item(&kiosk, id_), true);
            assert_eq(kiosk::is_locked(&kiosk, id_), false);
            assert_eq(kiosk::is_listed(&kiosk, id_), false);

            let purchase_cap = kiosk::list_with_purchase_cap<Asset>(
                &mut kiosk,
                &cap,
                id_,
                min_price,
                ts::ctx(scenario)
            );

            assert_eq(kiosk::is_listed(&kiosk, id_), true);
            assert_eq(kiosk::is_listed_exclusively(&kiosk, id_), true);

            transfer::public_transfer(purchase_cap, TEST_ADDRESS2);
            
            ts::return_shared(kiosk);
            ts::return_shared(shared);
            ts::return_to_sender(scenario, cap);
        };
        // address2 wants to buy asset from address1 kiosks
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let purchase_cap = ts::take_from_sender<PurchaseCap<Asset>>(scenario);
            let id_ = at::get_id(&shared, 0);

            assert_eq(kiosk::has_item(&kiosk, id_), true);

            let (asset, request) = kiosk::purchase_with_cap<Asset>(
                &mut kiosk,
                purchase_cap,
                mint_for_testing(10000, ts::ctx(scenario))
            );

            assert_eq(kiosk::has_item(&kiosk, id_), false);
            policy::confirm_request(&policy, request);

            transfer::public_transfer(asset, TEST_ADDRESS2);

            ts::return_shared(kiosk);
            ts::return_shared(shared);
            ts::return_shared(policy);
        };
        // address2 hasnt got any kiosk. He has to create one.
        next_tx(scenario, TEST_ADDRESS2);
        {
            at::create_kiosk(ts::ctx(scenario));
        };
        // address2 has to add extensions to place any asset
        helper_add_extensions(scenario, TEST_ADDRESS2, 01);
        // address2 wants to sell his asset in his own kiosk. 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let kiosk = ts::take_shared<Kiosk>(scenario);
            let cap = ts::take_from_sender<KioskOwnerCap>(scenario);
            let asset = ts::take_from_sender<Asset>(scenario);
            
            at::add_kiosk(&cap, &mut kiosk, asset);

            ts::return_shared(kiosk);
            ts::return_to_sender(scenario, cap); 
        };
        ts::end(scenario_test);
    }
}