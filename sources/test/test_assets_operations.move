// #[test_only]
// module notary::test_ListedAssetss_operations {
//     use sui::transfer;
//     use sui::coin::{Self, mint_for_testing};
//     use sui::test_scenario::{Self as ts, next_tx};
//     use sui::test_utils::{assert_eq};

//     use std::string::{Self,String};

//     use notary::helpers::{
//         Self,
//         init_test_helper, helper_create_account, helper_create_land, helper_create_house, 
//         helper_create_car, helper_create_shop, helper_create_all, helper_approve_all, 
//         helper_add_table_house, helper_add_all_table
//         };

//     use notary::lira_stable_coin::{LIRA_STABLE_COIN};

//     use notary::assets::{
//         Self, House, Land, Car, Shop, Sales, return_house_bool, return_car_bool,
//         return_land_bool, return_shop_bool, return_house_id, return_house_owner
//         };
    
//     use notary::assets_operation::{Self as ao, NotaryData, ListedAssets, Account, AdminCap};
    

//     const ADMIN: address = @0xA;
//     const TEST_ADDRESS1: address = @0xB;
//     const TEST_ADDRESS2: address = @0xC;
//     const TEST_ADDRESS3: address = @0xD;
//     const TEST_ADDRESS4: address = @0xE;

//    #[test]
//     public fun test_create() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
        
//         // Create 3 account, deposit 1000 and send them.
//         helper_create_account(scenario);

//         // check the user balance 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//              // take account object from sender
//             let account = ts::take_from_sender<Account>(scenario); 
//             // return the user balance 
//             let user_balance =  ao::user_account_balance(&account);
//             // user balance should be equal to 1000
//             assert_eq(user_balance, 1000);

//             // return the account object to sender 
//             ts::return_to_sender(scenario, account);
//         };
//         // Test_address1 create an House 
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             // define variables for create house object
//             let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let location = string::utf8(b"ankara");
//             let area: u64 = 144;
//             let year: u64 = 10;
//             let price: u64 = 500;

//             ao::create_house(
//              &mut listedsasset_share,
//            &mut account,
//                     location,
//                     area,
//                     year,
//                     price,
//                ts::ctx(scenario)
//              );
//             ts::return_to_sender(scenario, account);
//             ts::return_shared(listedsasset_share);
//         };
//         // check the house object
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let house = ts::take_from_sender<House>(scenario);
//             ts::return_to_sender(scenario, house);
//         };
        
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_add_house() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_create_account(scenario);
//         helper_create_all(scenario);

//         // send only house to table  for approve 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset_share = ts::take_shared<ListedAssets>(scenario);
//             let house = ts::take_from_sender<House>(scenario);
            
//             ao::add_house_table(&mut asset_share, house, ts::ctx(scenario));

//             ts::return_shared(asset_share);
//         };
//         // create another house 
//         helper_create_all(scenario);

//         // send only house to table  for approve 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset_share = ts::take_shared<ListedAssets>(scenario);
//             let house = ts::take_from_sender<House>(scenario);
            
//             ao::add_house_table(&mut asset_share, house, ts::ctx(scenario));

//             ts::return_shared(asset_share);
//         };
//         // in the table test_address1 has two house. Lets check them. 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset_share = ts::take_shared<ListedAssets>(scenario);
//             // borrow house1
//             let item1 = ao::get_house_table(&asset_share, 1, ts::ctx(scenario));
//             // borrow house2
//             let item2 = ao::get_house_table(&asset_share, 2, ts::ctx(scenario));

//             ts::return_shared(asset_share);
//         };
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_approve() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_create_account(scenario);
//         helper_create_all(scenario);
//         helper_add_table_house(scenario);
//         // approve the house 
//         next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let asset_share = ts::take_shared<ListedAssets>(scenario); 
//             ao::approve_house(&admin_cap, &mut asset_share, TEST_ADDRESS1);

//             ts::return_shared(asset_share);
//             ts::return_to_sender(scenario, admin_cap);

//         };
//         // Owner should has the item 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let house = ts::take_from_sender<House>(scenario);
//             // it has been approved so it should return true 
//             assert_eq(return_house_bool(&house), true);
//             ts::return_to_sender(scenario, house);
//         };
//         ts::end(scenario_test);
//     }

//    // We are expecting error. There is no assset in table. 
//     #[test]
//     #[expected_failure(abort_code = ao::ERROR_EMPTY_TABLE)]
//     public fun test_error_not_approved() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_create_account(scenario);
//         helper_create_all(scenario);
//         helper_add_all_table(scenario);
//         helper_approve_all(scenario);
//         helpers::helper_approve_house(scenario);

//         ts::end(scenario_test);
//     }
//      // We are expecting error. Admin already approved this asset. 
//     #[test]
//     #[expected_failure(abort_code = ao::ERROR_ASSET_ALREADY_APPROVED)]
//     public fun test_error_already_approved() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         helper_create_account(scenario);
//         helper_create_all(scenario);
//         helper_add_all_table(scenario);
//         helper_approve_all(scenario);
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
//             let house = ts::take_from_sender<House>(scenario);
//             ao::add_house_table(&mut listed_asset_shared, house, ts::ctx(scenario));

//             ts::return_shared(listed_asset_shared);
//         };

//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_approve2() {

//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;

//         // create 3 account and send them 1000 stabil coin
//         helper_create_account(scenario);
//         helper_create_all(scenario);
//         helper_add_all_table(scenario);
//         helper_approve_all(scenario);
    
//         // lets check that test_address1 object has been approved
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let house = ts::take_from_sender<House>(scenario);
//             // lets call house bool 
//             let approve = return_house_bool(&mut house);
//             // bool must be equal to true 
//             assert_eq(approve, true);

//             ts::return_to_sender(scenario, house);
//         };
//         // lets check that test_address1 object has been approved
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let car = ts::take_from_sender<Car>(scenario);
//             // lets call house bool 
//             let approve = return_car_bool(&mut car);
//             // bool must be equal to true 
//             assert_eq(approve, true);

//             ts::return_to_sender(scenario, car);
//         };
//         // lets check that test_address1 object has been approved
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let land = ts::take_from_sender<Land>(scenario);
//             // lets call house bool 
//             let approve = return_land_bool(&mut land);
//             // bool must be equal to true 
//             assert_eq(approve, true);

//             ts::return_to_sender(scenario, land);
//         };
//         // lets check that test_address1 object has been approved
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let shop = ts::take_from_sender<Shop>(scenario);
//             // lets call house bool 
//             let approve = return_shop_bool(&mut shop);
//             // bool must be equal to true 
//             assert_eq(approve, true);

//             ts::return_to_sender(scenario, shop);
//         };

//         ts::end(scenario_test);
//     }











// }