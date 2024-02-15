// #[test_only]
// module notary::test_ListedAssetss_operations {
//     use sui::transfer;
//     use sui::test_scenario::{Self as ts, next_tx};
//     use sui::test_utils::{assert_eq};

//     use std::string::{Self};

//     use notary::helpers::{
//     init_test_helper, helper_create_account, helper_add_types, helper_create_asset,
//     helper_add_accessory, helper_add_asset_table
//     };

//     use notary::assets::{Self, Asset};
    
//     use notary::assets_operation::{Self as ao, ListedAssets, AdminCap, Account};
    
//     const ADMIN: address = @0xA;
//     const TEST_ADDRESS1: address = @0xB;
//     const TEST_ADDRESS2: address = @0xC;
    
//    #[test]
//     public fun test_create_accounts() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
//         // create 4 Account and send them 1000 lira
//         helper_create_account(scenario);
//         // check the Test_address1 balance 
//         next_tx(scenario, TEST_ADDRESS1);
//         {  
//             let account = ts::take_from_sender<Account>(scenario);
//             let balance = ao::get_account_balance(&account);
//             assert_eq(balance, 1000);
//             ts::return_to_sender(scenario, account);
//         };
//         // check the Test_address2 balance 
//         next_tx(scenario, TEST_ADDRESS2);
//         {  
//             let account = ts::take_from_sender<Account>(scenario);
//             let balance = ao::get_account_balance(&account);
//             assert_eq(balance, 1000);
//             ts::return_to_sender(scenario, account);
//         };
//         // debt must be zero 
//         next_tx(scenario, TEST_ADDRESS1);
//         {  
//             let account = ts::take_from_sender<Account>(scenario);
//             let balance = ao::get_account_debt(&account);
//             assert_eq(balance, 0);
//             ts::return_to_sender(scenario, account);
//         };
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun create_asset() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
//         // create 4 Account and send them 1000 lira
//         helper_create_account(scenario);
//         // admin should create types 
//         helper_add_types(scenario);
//         // create a Asset object
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let listed_shared = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let amount: u64 = 900;
//             let name = string::utf8(b"ankara");
//             let type = string::utf8(b"House");

//             let asset = ao::create_asset(
//                 &mut listed_shared,
//                 &mut account,
//                 type,
//                 amount, 
//                 ts::ctx(scenario)
//             );
//             transfer::public_transfer(asset, TEST_ADDRESS1);

//             // check the admin balance. It should be equal to 5.
//             let admin_balance = ao::get_admin_balance(&listed_shared);
//             //assert_eq(admin_balance, 5);

//             ts::return_shared(listed_shared);
//             ts::return_to_sender(scenario, account);
//         };
//         // check the user's object 
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let asset = ts::take_from_sender<Asset>(scenario);
//             ts::return_to_sender(scenario, asset)
//         };
  
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_add_accessory() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
//         // create 4 Account and send them 1000 lira
//         helper_create_account(scenario);
//         // admin should create types 
//         helper_add_types(scenario);
//         // create an asset
//         helper_create_asset(scenario);
//         // add an property to asset
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset = ts::take_from_sender<Asset>(scenario);
//             let property = string::utf8(b"4+1");

//             ao::add_accessory(&mut asset, property, ts::ctx(scenario));

//             let asset_id = assets::get_accessory_vector_id(&asset);      
//             let accesory = assets::get_accessory_table(&asset, asset_id);
//             let property2 = assets::get_accessory_property(accesory);
            
//             assert_eq(property, property2);

//             ts::return_to_sender(scenario, asset);
//         };
     
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_add_asset_table() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
//         // create 4 Account and send them 1000 lira
//         helper_create_account(scenario);
//         // admin should create types 
//         helper_add_types(scenario);
//         // create an asset
//         helper_create_asset(scenario);
//         // create an accessory
//         helper_add_accessory(scenario, b"4+1");
//         // add asset to table for approve 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let shared = ts::take_shared<ListedAssets>(scenario);
//             let asset = ts::take_from_sender<Asset>(scenario);
//             let asset_id = assets::get_asset_id(&asset);

//             ao::add_asset_table(&mut shared, asset);

//             let asset = ao::get_asset(&shared, asset_id);
//             let property_id = assets::get_accessory_vector_id(asset);
//             let accessory = assets::get_accessory_table(asset, property_id);
//             let property = assets::get_accessory_property(accessory);
//             let property2 = string::utf8(b"4+1");

//             assert_eq(property, property2);

//             ts::return_shared(shared);
//         };
//         ts::end(scenario_test);
//     }

//     #[test]
//     public fun test_approve_asset() {
//         let scenario_test = init_test_helper();
//         let scenario = &mut scenario_test;
//         // create 4 Account and send them 1000 lira
//         helper_create_account(scenario);
//         // admin should create types 
//         helper_add_types(scenario);
//         // create an asset
//         helper_create_asset(scenario);
//         // create an accessory
//         helper_add_accessory(scenario, b"4+1");
//         // add asset to table 
//         helper_add_asset_table(scenario);
//         // There are two conditions false and true. Scenario 1 is admin is not going to approve 
//         next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let shared = ts::take_shared<ListedAssets>(scenario);
//             let id = ao::get_asset_id(&shared, 0);
//             let decision = false; 

//             ao::approve_asset(&admin_cap, &mut shared, id, decision);

//             ts::return_shared(shared);
//             ts::return_to_sender(scenario, admin_cap);
//         };

//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset = ts::take_from_sender<Asset>(scenario);
//             assert_eq(assets::is_approved(&asset), false);

//             ts::return_to_sender(scenario, asset);
//         };
//         // asset is not approved. So we have to add again to table . 
//         helper_add_asset_table(scenario);
//         // admin decided to approve it now. 
//         next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let shared = ts::take_shared<ListedAssets>(scenario);
//             let id = ao::get_asset_id(&shared, 0);
//             let decision = true; 

//             ao::approve_asset(&admin_cap, &mut shared, id, decision);

//             ts::return_shared(shared);
//             ts::return_to_sender(scenario, admin_cap);
//         };
//         // asset approved bool should be return true now. 
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset = ts::take_from_sender<Asset>(scenario);
//             assert_eq(assets::is_approved(&asset), true);

//             ts::return_to_sender(scenario, asset);
//         };
//          ts::end(scenario_test);
//     }

// }