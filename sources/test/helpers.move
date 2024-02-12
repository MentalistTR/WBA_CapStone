#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};

    use notary::assets_operation::{Self as ao, test_init, Account};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

    use notary::assets::{Self,};

    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;


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

    // public fun helper_create_all(scenario: &mut Scenario) {

    // }

    

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