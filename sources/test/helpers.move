#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};

    use std::string;


    use notary::assets_operation::{Self as ao, test_init, Account, Asset};
    use notary::lira_stable_coin::{return_init_lira};
    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;
    const TEST_ADDRESS4: address = @0xE;

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

    public fun helper_create_house(
        scenario: &mut Scenario,
        test_location: vector<u8>,
        test_area: u64,
        test_year: u64,
        test_price: u64
        ) {

        next_tx(scenario, TEST_ADDRESS1);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(test_location);
            let area: u64 = test_area;
            let year: u64 = test_year;
            let price: u64 = test_price;

            ao::create_House(
                &mut asset_share,
                &mut account,
                location,
                area,
                year,
                price,
                ts::ctx(scenario)
             );
            ts::return_to_sender(scenario, account);
            ts::return_shared(asset_share);
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