#[test_only]
module notary::test_assets_type {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::kiosk::{Self, Kiosk};
    use sui::transfer_policy::{TransferPolicy, TransferPolicyCap};
    use sui::object;
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing};
    use sui::coin::{Self, Coin};
    
    use std::string::{Self};
    use std::vector::{Self};
    use std::option;

    use notary::assets::{Self, Asset};

    use notary::helpers::{init_test_helper, helper_add_types,
    helper_new_policy};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes};

    use rules::royalty_rule::{Self as rr, NotaryFee, return_notary_fee};
    use rules::lira::{LIRA};
    
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
        // TEST_ADDRESS1 had created an kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));
          
            ts::return_shared(shared);
        };

        let kiosk1_data = next_tx(scenario, TEST_ADDRESS1);
     
        // TEST_ADDRESS2 had created an kiosk
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            at::create_kiosk(&mut shared, ts::ctx(scenario));

            ts::return_shared(shared);
        };
        let kiosk2_data = next_tx(scenario, TEST_ADDRESS2);
       
        // admin should create an transferpolicy
        helper_new_policy<Asset>(scenario);
        // create types such as House, Car, Land, Shop
        helper_add_types(scenario);
        // Admin adds new rules for royalty
        next_tx(scenario, ADMIN);
        {
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let cap = ts::take_from_sender<TransferPolicyCap<Asset>>(scenario);
            
            rr::add<Asset>(&mut policy, &cap);

            ts::return_shared(policy);
            ts::return_to_sender(scenario, cap);
        };

        // create an asset 1 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 

            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

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
          let asset_id1 = object::last_created(ts::ctx(scenario));

        // create an asset 2 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 

            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id); 
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

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

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 
            
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

        // ADMIN should approve the asset 2 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 
            
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
        // Asset 1 's owner make new property for his own asset
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 
        
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let listed_shared = ts::take_shared<ListedTypes>(scenario);

            let size = string::utf8(b"size");
            let number = string::utf8(b"144m2");

            at::new_property(
                & listed_shared,
                &mut kiosk1_shared,
                asset_id1,
                size,
                number,
                ts::ctx(scenario)  
            );
            let kiosk_cap = at::get_kiosk_cap(&listed_shared, ts::ctx(scenario) );

            let item = kiosk::borrow<Asset>(&kiosk1_shared, kiosk_cap, asset_id1);

            assert_eq(assets::is_approved(item), false);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(listed_shared);
        };

        // ADMIN should approve the asset 1 before users list on kiosk 
        next_tx(scenario, ADMIN);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 
            
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

        // TEST_ADDRESS1 Listing the asset 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 

            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);

            let shared = ts::take_shared<ListedTypes>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let asset_id = asset_id1;

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), false);            
            
            at::list(
                &mut shared,
                &mut kiosk1_shared,
                asset_id,
                10000,
                ts::ctx(scenario)
            );
            assert_eq(kiosk::is_listed(&kiosk1_shared, asset_id), true);

            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(shared);
        };

        // TEST_ADDRESS2 is going to buy asset from address 1
        next_tx(scenario, TEST_ADDRESS2);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            let kiosk1_created = ts::created(&kiosk1_data);
        
            let kiosk1_id = vector::borrow(&kiosk1_created, 0);

            let kiosk2_created = ts::created(&kiosk2_data);
        
            let kiosk2_id = vector::borrow(&kiosk2_created, 0); 
           
            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let notary_fee = ts::take_shared<NotaryFee>(scenario);

            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let asset_id = asset_id1;

            let payment = mint_for_testing<SUI>(10000, ts::ctx(scenario));
            let fee = mint_for_testing<LIRA>(1000000001, ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), true);
            assert_eq(kiosk::has_item(&kiosk2_shared, asset_id), false);

            at::purchase(
                &mut kiosk1_shared,
                &mut kiosk2_shared ,
                &mut shared,
                &mut notary_fee,
                &policy,
                asset_id1,
                payment,
                fee,
                ts::ctx(scenario)
            );

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id), false);
            assert_eq(kiosk::has_item(&kiosk2_shared, asset_id), true);

            let lira = return_notary_fee(&notary_fee);
            assert_eq(lira,1_000_000_000);

            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(shared);
            ts::return_shared(notary_fee);
        };
        // withdraw the profits from kiosk
        next_tx(scenario, TEST_ADDRESS1);
        {
            let kiosk1_ = ts::created(&kiosk1_data);
      
            let kiosk1_id = vector::borrow(&kiosk1_, 0); 

            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let shared = ts::take_shared<ListedTypes>(scenario);
          

            assert_eq(kiosk::profits_amount(&kiosk1_shared), 10000);

            let profit = at::withdraw_profits(
                &mut kiosk1_shared,
                &shared,
                option::some(10000),
                ts::ctx(scenario)
                );
            assert_eq(kiosk::profits_amount(&kiosk1_shared), 0);

            transfer::public_transfer(profit, TEST_ADDRESS1);

            ts::return_shared(kiosk1_shared);
            ts::return_shared(shared);
        };
        // check the Owner of kiosk balance 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let user_balance = ts::take_from_sender<Coin<SUI>>(scenario);
            assert_eq(coin::value(&user_balance), 10000);
            ts::return_to_sender(scenario, user_balance);
        };
        // check the Test Address2 kiosk's and he will list in on his kiosk. 
        next_tx(scenario, TEST_ADDRESS2);
        {
            let kiosk2 = ts::created(&kiosk2_data);
            let kiosk2_id = vector::borrow(&kiosk2, 0);

            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);

            let shared = ts::take_shared<ListedTypes>(scenario);
            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);
            let asset_id = asset_id1;
    
            assert_eq(kiosk::has_item(&kiosk2_shared, asset_id), true);
            assert_eq(kiosk::is_locked(&kiosk2_shared, asset_id), false);
            assert_eq(kiosk::is_listed(&kiosk2_shared, asset_id), false);            
            
            at::list(
                &mut shared,
                &mut kiosk2_shared,
                asset_id,
                10000,
                ts::ctx(scenario)
            );
            assert_eq(kiosk::is_listed(&kiosk2_shared, asset_id), true);

            ts::return_shared(policy);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(shared);
        };
   
         // TEST_ADDRESS1 is going to buy asset from TEST_ADDRESS2
        next_tx(scenario, TEST_ADDRESS1);
        {
            let shared = ts::take_shared<ListedTypes>(scenario);

            let kiosk1_created = ts::created(&kiosk1_data);
        
            let kiosk1_id = vector::borrow(&kiosk1_created, 0); 

            let kiosk2_created = ts::created(&kiosk2_data);
            let kiosk2_id = vector::borrow(&kiosk2_created, 0); 

            let kiosk1_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk1_id);
            let kiosk2_shared = ts::take_shared_by_id<Kiosk>(scenario, *kiosk2_id);
            let notary_fee = ts::take_shared<NotaryFee>(scenario);

            let policy = ts::take_shared<TransferPolicy<Asset>>(scenario);

            let payment = mint_for_testing<SUI>(10000, ts::ctx(scenario));
            let fee = mint_for_testing<LIRA>(1000000001, ts::ctx(scenario));

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id1), false);
            assert_eq(kiosk::has_item(&kiosk2_shared, asset_id1), true);

            at::purchase(
                &mut kiosk2_shared,
                &mut kiosk1_shared ,
                &mut shared,
                &mut notary_fee,
                &policy,
                asset_id1,
                payment,
                fee,
                ts::ctx(scenario)
            );

            let lira = return_notary_fee(&notary_fee);
            assert_eq(lira,2_000_000_000);

            assert_eq(kiosk::has_item(&kiosk1_shared, asset_id1), true);
            assert_eq(kiosk::has_item(&kiosk2_shared, asset_id1), false);

            ts::return_shared(policy);
            ts::return_shared(kiosk1_shared);
            ts::return_shared(kiosk2_shared);
            ts::return_shared(shared);
            ts::return_shared(notary_fee);

        };
        next_tx(scenario, TEST_ADDRESS1);
        {
            let user_balance = ts::take_from_sender<Coin<SUI>>(scenario);
            assert_eq(coin::value(&user_balance), 10000);
            ts::return_to_sender(scenario, user_balance);
        };

        ts::end(scenario_test);
    }
}
