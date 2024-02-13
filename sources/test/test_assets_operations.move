#[test_only]
module notary::test_ListedAssetss_operations {
    use sui::transfer;
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};

    use std::string::{Self};

    use notary::helpers::{Test, init_test_helper, helper_create_account, helper_create_share_listed, helper_return_test};

    use notary::assets::{Asset};
    
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
        // create a share object only one time
        helper_create_share_listed(scenario);
        // create a Asset object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let listed_shared = ts::take_shared<ListedAssets<Test>>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let amount: u64 = 900;
            let name = string::utf8(b"ankara");
            let type = helper_return_test(scenario, name);

            let asset = ao::create_asset<Test>(
                &mut listed_shared,
                &mut account,
                type,
                amount, 
                ts::ctx(scenario)
            );
            transfer::public_transfer(asset, TEST_ADDRESS1);

            // check the admin balance. It should be equal to 5.
            let admin_balance = ao::get_admin_balance(&listed_shared);
            assert_eq(admin_balance, 5);

            ts::return_shared(listed_shared);
            ts::return_to_sender(scenario, account);
        };
        // check the user's object 
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<Asset<Test>>(scenario);
            ts::return_to_sender(scenario, asset)
        };
  
        ts::end(scenario_test);
    }


}