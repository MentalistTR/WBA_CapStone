#[test_only]
module notary::test_assets_operations {
    use sui::transfer;
    use sui::coin::{Self, mint_for_testing};
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};

    use std::string::{Self,String};

    use notary::helpers::{
        init_test_helper, helper_create_account, helper_create_land, helper_create_house, 
        helper_create_car, helper_create_shop
        };

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{Self, House, Land, Car, Shop, Sales, return_house_bool};
    
    use notary::assets_operation::{Self as ao, Data, Asset, Account, AdminCap};
    

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;
    const TEST_ADDRESS4: address = @0xE;

   #[test]
    public fun test_create() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // Create 3 account, deposit 1000 and send them.
        helper_create_account(scenario);

        // check the user balance 
        next_tx(scenario, TEST_ADDRESS1);
        {
             // take account object from sender
            let account = ts::take_from_sender<Account>(scenario); 
            // return the user balance 
            let user_balance =  ao::user_account_balance(&account);
            // user balance should be equal to 1000
            assert_eq(user_balance, 1000);

            // return the account object to sender 
            ts::return_to_sender(scenario, account);
        };
        // Test_address1 create an House 
        next_tx(scenario, TEST_ADDRESS1);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(b"ankara");
            let area: u64 = 144;
            let year: u64 = 10;
            let price: u64 = 500;

            ao::create_house(
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
        // check the house object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let house = ts::take_from_sender<House>(scenario);
            ts::return_to_sender(scenario, house);
        };
        
        ts::end(scenario_test);
    }

    #[test]
    public fun test_approve() {

        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create 3 account and send them 1000 stabil coin
        helper_create_account(scenario);

        let location = b"ankara";
        let area : u64 = 144;
        let year : u64 = 10;
        let price: u64 = 1000;

        // create an house for test_address1
        helper_create_house(
            scenario,
            TEST_ADDRESS1,
            location,
            area,
            year,
            price
            );

        // owner must approve that asset
        next_tx(scenario, ADMIN);
        {   
            let house = ts::take_from_address<House>(scenario, TEST_ADDRESS1);
            let admincap = ts::take_from_sender<AdminCap>(scenario);

            ao::approve_house(&admincap, &mut house);

            ts::return_to_address(TEST_ADDRESS1, house);
            ts::return_to_sender(scenario, admincap);
        };
        // lets check that test_address1 object has been approved
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let house = ts::take_from_sender<House>(scenario);
            // lets call house bool 
            let approve = return_house_bool(&mut house);

            assert_eq(approve, true);

            ts::return_to_sender(scenario, house);
        };






















        ts::end(scenario_test);

}

}