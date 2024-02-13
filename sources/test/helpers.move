#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};

    use std::string::{Self, String};

    use notary::assets_operation::{Self as ao, AdminCap, Account, ListedAssets, test_init};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;

     struct Test has  store {
        type: String
    }

    public fun helper_create_account(scenario: &mut Scenario) {
        // TEST_ADDRESS1
        next_tx(scenario, TEST_ADDRESS1);
        {
            let account = ao::new_account(ts::ctx(scenario));
            transfer::public_transfer(account, TEST_ADDRESS1);
        };
        next_tx(scenario, TEST_ADDRESS1);
        {
            let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
            let account = ts::take_from_sender<Account>(scenario);

            ao::deposit(&mut account, deposit_amount);
            ts::return_to_sender(scenario, account);
        };
         // TEST_ADDRESS2
           next_tx(scenario, TEST_ADDRESS2);
        {
            let account = ao::new_account(ts::ctx(scenario));
            transfer::public_transfer(account, TEST_ADDRESS2);
        };
        next_tx(scenario, TEST_ADDRESS2);
        {
            let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
            let account = ts::take_from_sender<Account>(scenario);

            ao::deposit(&mut account, deposit_amount);
            ts::return_to_sender(scenario, account);
        };
         // TEST_ADDRESS3
        next_tx(scenario, TEST_ADDRESS3);
        {
            let account = ao::new_account(ts::ctx(scenario));
            transfer::public_transfer(account, TEST_ADDRESS3);
        };
        next_tx(scenario, TEST_ADDRESS3);
        {
            let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
            let account = ts::take_from_sender<Account>(scenario);

            ao::deposit(&mut account, deposit_amount);
            ts::return_to_sender(scenario, account);
        };
    }
    public fun helper_create_asset(scenario: &mut Scenario) {
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

            ts::return_shared(listed_shared);
            ts::return_to_sender(scenario, account);
        };
    }

    public fun helper_create_share_listed(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN); 
        {
        let admin_cap = ts::take_from_sender<AdminCap>(scenario);
        ao::new_listed_assets<Test>(&admin_cap, ts::ctx(scenario));
        ts::return_to_sender(scenario,admin_cap);
        };
    }

    // public fun helper_create_all(scenario: &mut Scenario) {

    // }

    // create a test object for create a Asset
    public fun helper_return_test(_scenario: &mut Scenario, type: String) : Test {
        let test= Test{
            type: type
    };
        test
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
