#[test_only]
module notary::test_ListedAssetss_operations {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};

    use std::string::{Self};

    use notary::helpers::{init_test_helper, helper_create_account, helper_add_types, helper_create_asset};

    use notary::assets::{Self, Asset};
    
    use notary::assets_operation::{Self as ao, ListedAssets, Account};
    

    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    
   #[test]
    public fun test_create_accounts() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create 4 Account and send them 1000 lira
        helper_create_account(scenario);
        // check the Test_address1 balance 
        next_tx(scenario, TEST_ADDRESS1);
        {  
            let account = ts::take_from_sender<Account>(scenario);
            let balance = ao::get_account_balance(&account);
            assert_eq(balance, 1000);
            ts::return_to_sender(scenario, account);
        };
        // check the Test_address2 balance 
        next_tx(scenario, TEST_ADDRESS2);
        {  
            let account = ts::take_from_sender<Account>(scenario);
            let balance = ao::get_account_balance(&account);
            assert_eq(balance, 1000);
            ts::return_to_sender(scenario, account);
        };
        // debt must be zero 
        next_tx(scenario, TEST_ADDRESS1);
        {  
            let account = ts::take_from_sender<Account>(scenario);
            let balance = ao::get_account_debt(&account);
            assert_eq(balance, 0);
            ts::return_to_sender(scenario, account);
        };
        ts::end(scenario_test);
    }

    #[test]
    public fun create_asset() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create 4 Account and send them 1000 lira
        helper_create_account(scenario);
        // admin should create types 
        helper_add_types(scenario);
        // create a Asset object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let listed_shared = ts::take_shared<ListedAssets>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let amount: u64 = 900;
            let name = string::utf8(b"ankara");
            let type = string::utf8(b"House");

            let asset = ao::create_asset(
                &mut listed_shared,
                &mut account,
                type,
                amount, 
                ts::ctx(scenario)
            );
            transfer::public_transfer(asset, TEST_ADDRESS1);

            // check the admin balance. It should be equal to 5.
            let admin_balance = ao::get_admin_balance(&listed_shared);
            //assert_eq(admin_balance, 5);

            ts::return_shared(listed_shared);
            ts::return_to_sender(scenario, account);
        };
        // check the user's object 
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<Asset>(scenario);
            ts::return_to_sender(scenario, asset)
        };
  
        ts::end(scenario_test);
    }

    #[test]
    public fun test_add_accessory() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // create 4 Account and send them 1000 lira
        helper_create_account(scenario);
        // admin should create types 
        helper_add_types(scenario);
        // create an asset
        helper_create_asset(scenario);

        // add an property to asset
        next_tx(scenario, TEST_ADDRESS1);
        {
            let asset = ts::take_from_sender<Asset>(scenario);
          
            let property = string::utf8(b"4+1");

            let asset_id =  ao::add_accessory(&mut asset, property, ts::ctx(scenario));

            let accesory = assets::return_property(&asset, asset_id);
            let property2 = assets::return_accessory_property(accesory);
            assert_eq(property, property2);

            ts::return_to_sender(scenario, asset);
        };
     
        ts::end(scenario_test);

    }


}