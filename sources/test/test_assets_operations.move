#[test_only]
module notary::test_ListedAssetss_operations {
    use sui::transfer;
    use sui::coin::{Self, mint_for_testing};
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};

    use std::string::{Self,String};

    use notary::helpers::{
        init_test_helper, helper_create_account, helper_create_land, helper_create_house, 
        helper_create_car, helper_create_shop, helper_create_all, helper_approve_all,
        helper_approve_house, helper_add_table_house, // helper_add_all_table
        };

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{
        Self, House, Land, Car, Shop, Sales, return_house_bool, return_car_bool,
        return_land_bool, return_shop_bool, return_house_id, return_house_owner
        };
    
    use notary::assets_operation::{Self as ao, NotaryData, ListedAssets, Account, AdminCap};
    

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
            let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(b"ankara");
            let area: u64 = 144;
            let year: u64 = 10;
            let price: u64 = 500;

            ao::create_house(
             &mut listedsasset_share,
           &mut account,
                    location,
                    area,
                    year,
                    price,
               ts::ctx(scenario)
             );
            ts::return_to_sender(scenario, account);
            ts::return_shared(listedsasset_share);
        };
        // check the house object
        next_tx(scenario, TEST_ADDRESS1);
        {
            let house = ts::take_from_sender<House>(scenario);
            ts::return_to_sender(scenario, house);
        };
        
        ts::end(scenario_test);
    }

    // lets test linked list method now 
    // #[test]
    // public fun test_linked_add() {
    //     let scenario_test = init_test_helper();
    //     let scenario = &mut scenario_test;

    //     helper_create_all(scenario);

    //     next_tx(scenario, TEST_ADDRESS1);
    //     {


            
    //     }








    //     ts::end(scenario_test);

    // }




    // We are expecting error. Admin didint approve the ListedAssets. 
    #[test]
    #[expected_failure(abort_code = ao::ERROR_ASSET_NOT_APPROVED)]
    public fun test_error_not_approved() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        helper_create_account(scenario);
        helper_create_all(scenario);
        helper_add_table_house(scenario);

        ts::end(scenario_test);
    }

    #[test]
    public fun test_approve() {

        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        // create 3 account and send them 1000 stabil coin
        helper_create_account(scenario);

        let location = b"ankara";
        let model = b"focus";
        let color = b"red";
        let area : u64 = 144;
        let year : u64 = 10;
        let price: u64 = 1000;
        let distance: u64 = 50000;

        // create a house for test_address1
        helper_create_house(
            scenario,
            TEST_ADDRESS1,
            location,
            area,
            year,
            price
            );
        // create a shop for test_address1
        helper_create_land(
            scenario,
            TEST_ADDRESS1,
            location,
            area,
            price
        );
        // create a shop for test_address1
        helper_create_shop(
            scenario,
            TEST_ADDRESS1,
            location,
            area,
            year,
            price
        );
        helper_create_car(
            scenario,
            TEST_ADDRESS1,
            model,
            year,
            color,
            distance,
            price
        );

        // owner must approve that House 
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
            // bool must be equal to true 
            assert_eq(approve, true);

            ts::return_to_sender(scenario, house);
        };

         // owner must approve that Car
        next_tx(scenario, ADMIN);
        {   
            let car = ts::take_from_address<Car>(scenario, TEST_ADDRESS1);
            let admincap = ts::take_from_sender<AdminCap>(scenario);

            ao::approve_car(&admincap, &mut car);

            ts::return_to_address(TEST_ADDRESS1, car);
            ts::return_to_sender(scenario, admincap);
        };
        // lets check that test_address1 object has been approved
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let car = ts::take_from_sender<Car>(scenario);
            // lets call house bool 
            let approve = return_car_bool(&mut car);
            // bool must be equal to true 
            assert_eq(approve, true);

            ts::return_to_sender(scenario, car);
        };

        // owner must approve that Land
        next_tx(scenario, ADMIN);
        {   
            let land = ts::take_from_address<Land>(scenario, TEST_ADDRESS1);
            let admincap = ts::take_from_sender<AdminCap>(scenario);

            ao::approve_land(&admincap, &mut land);

            ts::return_to_address(TEST_ADDRESS1, land);
            ts::return_to_sender(scenario, admincap);
        };
        // lets check that test_address1 object has been approved
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let land = ts::take_from_sender<Land>(scenario);
            // lets call house bool 
            let approve = return_land_bool(&mut land);
            // bool must be equal to true 
            assert_eq(approve, true);

            ts::return_to_sender(scenario, land);
        };

         // owner must approve that Shop
        next_tx(scenario, ADMIN);
        {   
            let shop = ts::take_from_address<Shop>(scenario, TEST_ADDRESS1);
            let admincap = ts::take_from_sender<AdminCap>(scenario);

            ao::approve_shop(&admincap, &mut shop);

            ts::return_to_address(TEST_ADDRESS1, shop);
            ts::return_to_sender(scenario, admincap);
        };
        // lets check that test_address1 object has been approved
        next_tx(scenario, TEST_ADDRESS1);
        {   
            let shop = ts::take_from_sender<Shop>(scenario);
            // lets call house bool 
            let approve = return_shop_bool(&mut shop);
            // bool must be equal to true 
            assert_eq(approve, true);

            ts::return_to_sender(scenario, shop);
        };

        ts::end(scenario_test);
    }
    // Admin already approved the ListedAssets. We are expecting error
    #[test]
    #[expected_failure(abort_code = ao::ERROR_ALREADY_APPROVED)]
    public fun test_error_already_approved() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        helper_create_account(scenario);
        helper_create_all(scenario);
        helper_approve_all(scenario);
        helper_approve_house(scenario);

        ts::end(scenario_test);
    }

    // #[test]
    // public fun test_add_table() {

    //     let scenario_test = init_test_helper();
    //     let scenario = &mut scenario_test;

    //     helper_create_account(scenario);
    //     helper_create_all(scenario);
    //     helper_approve_all(scenario);

    //     //Add ListedAssets to table
    //     next_tx(scenario, TEST_ADDRESS1);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let house = ts::take_from_sender<House>(scenario);
    //         // keep ID before add the table 
    //         let house_id = return_house_id(&house);
    //         // add house to the table 
    //         ao::add_house_table(&mut listed_asset_shared, house, ts::ctx(scenario));
    //         // get house object from table 
    //         let house_table = ao::get_house_table(&listed_asset_shared, house_id, ts::ctx(scenario));
    //         // return the house object owner 
    //         let house_owner = return_house_owner(house_table);
    //         // check the owner variable from that object 
    //         assert_eq(house_owner, TEST_ADDRESS1);

    //         ts::return_shared(listed_asset_shared);
    //     };
    //     //Add ListedAssets to table
    //     next_tx(scenario, TEST_ADDRESS1);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let car = ts::take_from_sender<Car>(scenario);
    //         ao::add_car_table(&mut listed_asset_shared, car, ts::ctx(scenario));

    //         ts::return_shared(listed_asset_shared);
    //     };
    //      //Add ListedAssets to table
    //     next_tx(scenario, TEST_ADDRESS1);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let land = ts::take_from_sender<Land>(scenario);
    //         ao::add_land_table(&mut listed_asset_shared, land, ts::ctx(scenario));

    //         ts::return_shared(listed_asset_shared);
    //     };
    //     //Add ListedAssets to table
    //     next_tx(scenario, TEST_ADDRESS1);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let shop = ts::take_from_sender<Shop>(scenario);
    //         ao::add_shop_table(&mut listed_asset_shared, shop, ts::ctx(scenario));

    //         ts::return_shared(listed_asset_shared);
    //     };

    //      ts::end(scenario_test);
    // }

    // #[test]
    // public fun test_remove_object() {
    //     let scenario_test = init_test_helper();
    //     let scenario = &mut scenario_test;

    //     helper_create_account(scenario);
    //     helper_create_all(scenario);
    //     helper_approve_all(scenario);
    //     // add and remove the house from table
    //     next_tx(scenario, TEST_ADDRESS1);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let house = ts::take_from_sender<House>(scenario);
    //         let house_id = return_house_id(&house);
    //         ao::add_house_table(&mut listed_asset_shared, house, ts::ctx(scenario));
    //         ao::remove_house_table(&mut listed_asset_shared, house_id, ts::ctx(scenario));

    //         ts::return_shared(listed_asset_shared);
    //     };

    //     ts::end(scenario_test);
    // }
    // #[test]
    // #[expected_failure(abort_code = 0000000000000000000000000000000000000000000000000000000000000002::dynamic_field::EFieldDoesNotExist)]
    // public fun test_error_remove_object() {
    //     let scenario_test = init_test_helper();
    //     let scenario = &mut scenario_test;

    //     helper_create_account(scenario);
    //     helper_create_all(scenario);
    //     helper_approve_all(scenario);
    //     helper_add_all_table(scenario);
        
    //     // lets check that test_address2 try to remove another person object. 
    //     next_tx(scenario, TEST_ADDRESS2);
    //     {   
    //         let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
    //         let house_id = ao::get_house_id(&listed_asset_shared, 0);

    //         ao::remove_house_table(&mut listed_asset_shared, house_id, ts::ctx(scenario));

    //         ts::return_shared(listed_asset_shared);

    //     };

       // ts::end(scenario_test);

    //}















}