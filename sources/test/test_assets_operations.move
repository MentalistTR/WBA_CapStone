#[test_only]
module notary::test_ListedAssetss_operations {
    use sui::transfer;
    use sui::coin::{Self, Coin, mint_for_testing};
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};
    use sui::balance;
   
    use std::string::{Self,String};

    use notary::helpers::{Self, Test, init_test_helper, helper_create_account, helper_create_share_listed, helper_return_test};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{Self, Asset};
    
    use notary::assets_operation::{Self as ao, NotaryData, ListedAssets, Account, AdminCap};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;
    const TEST_ADDRESS4: address = @0xE;

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
            let type = helper_return_test(scenario);

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