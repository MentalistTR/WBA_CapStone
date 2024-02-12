// #[test_only]
// module notary::helpers {
//     use sui::test_scenario::{Self as ts, next_tx, Scenario};
//     use sui::transfer;
//     use sui::coin::{mint_for_testing};
//     use sui::test_utils::{assert_eq};

//     use std::string::{Self, String};
    


//     use notary::assets_operation::{Self as ao, test_init, Account, ListedAssets, AdminCap};

//     use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

//     use notary::assets::{
//         Self, House, Land, Car, Shop, Sales, return_house_bool, return_car_bool,
//         return_land_bool, return_shop_bool
//         };

//     const ADMIN: address = @0xA;
//     const TEST_ADDRESS1: address = @0xB;
//     const TEST_ADDRESS2: address = @0xC;
//     const TEST_ADDRESS3: address = @0xD;
//     const TEST_ADDRESS4: address = @0xE;

//     public fun helper_create_account(scenario: &mut Scenario) {
//         // TEST_ADDRESS1
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let account = ao::new_account(ts::ctx(scenario));

//             transfer::public_transfer(account, TEST_ADDRESS1);
//         };
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
//             let account = ts::take_from_sender<Account>(scenario);

//             ao::deposit(&mut account, deposit_amount);

//             ts::return_to_sender(scenario, account);
//         };
//          // TEST_ADDRESS2
//            next_tx(scenario, TEST_ADDRESS2);
//         {
//             let account = ao::new_account(ts::ctx(scenario));

//             transfer::public_transfer(account, TEST_ADDRESS2);
//         };
//         next_tx(scenario, TEST_ADDRESS2);
//         {
//             let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
//             let account = ts::take_from_sender<Account>(scenario);

//             ao::deposit(&mut account, deposit_amount);

//             ts::return_to_sender(scenario, account);
//         };
//          // TEST_ADDRESS3
//         next_tx(scenario, TEST_ADDRESS3);
//         {
//             let account = ao::new_account(ts::ctx(scenario));

//             transfer::public_transfer(account, TEST_ADDRESS3);
//         };
//         next_tx(scenario, TEST_ADDRESS3);
//         {
//             let deposit_amount = mint_for_testing<LIRA_STABLE_COIN>(1000, ts::ctx(scenario));
//             let account = ts::take_from_sender<Account>(scenario);

//             ao::deposit(&mut account, deposit_amount);

//             ts::return_to_sender(scenario, account);
//         };
//     }

//     public fun helper_create_house(
//         scenario: &mut Scenario,
//         sender: address,
//         test_location: vector<u8>,
//         test_area: u64,
//         test_year: u64,
//         test_price: u64
//         ) {

//         next_tx(scenario, sender);
//         {   
//             // define variables for create house object
//             let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let location = string::utf8(test_location);
//             let area: u64 = test_area;
//             let year: u64 = test_year;
//             let price: u64 = test_price;

//             ao::create_house(
//                 &mut listedsasset_share,
//                 &mut account,
//                 location,
//                 area,
//                 year,
//                 price,
//                 ts::ctx(scenario)
//              );
//             ts::return_to_sender(scenario, account);
//             ts::return_shared(listedsasset_share);
//         };
//     }

//      public fun helper_create_shop(
//         scenario: &mut Scenario,
//         sender: address,
//         test_location: vector<u8>,
//         test_area: u64,
//         test_year: u64,
//         test_price: u64
//         ) {

//         next_tx(scenario, sender);
//         {   
//             // define variables for create house object
//             let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let location = string::utf8(test_location);
//             let area: u64 = test_area;
//             let year: u64 = test_year;
//             let price: u64 = test_price;

//             ao::create_shop(
//                 &mut listedsasset_share,
//                 &mut account,
//                 location,
//                 area,
//                 year,
//                 price,
//                 ts::ctx(scenario)
//              );
//             ts::return_to_sender(scenario, account);
//             ts::return_shared(listedsasset_share);
//         }; 
//     }

//     public fun helper_create_land(
//         scenario: &mut Scenario,
//         sender: address,
//         test_location: vector<u8>,
//         test_area: u64,
//         test_price: u64
//         ) {

//         next_tx(scenario, sender);
//         {   
//             // define variables for create house object
//             let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let location = string::utf8(test_location);
//             let area: u64 = test_area;
//             let price: u64 = test_price;

//             ao::create_land(
//                 &mut listedsasset_share,
//                 &mut account,
//                 location,
//                 area,
//                 price,
//                 ts::ctx(scenario)
//              );
//             ts::return_to_sender(scenario, account);
//             ts::return_shared(listedsasset_share);
//         };
//     }

//     public fun helper_create_car(
//         scenario: &mut Scenario,
//         sender: address,
//         test_model: vector<u8>,
//         test_year: u64,
//         test_color: vector<u8>,
//         test_distance: u64,
//         test_price: u64
//         ) {

//         next_tx(scenario, sender);
//         {   
//             // define variables for create house object
//             let listedsasset_share = ts::take_shared<ListedAssets>(scenario);
//             let account = ts::take_from_sender<Account>(scenario);
//             let test_model = string::utf8(test_model);
//             let test_color = string::utf8(test_color);
         
        
//             let price: u64 = test_price;

//             ao::create_car(
//                 &mut listedsasset_share,
//                 &mut account,
//                 test_model,
//                 test_year,
//                 test_color,
//                 test_distance,
//                 test_price,
//                 ts::ctx(scenario)
//              );
//             ts::return_to_sender(scenario, account);
//             ts::return_shared(listedsasset_share);
//         };
//     }

//     public fun helper_create_all(scenario: &mut Scenario) {

//         let location = b"ankara";
//         let model = b"focus";
//         let color = b"red";
//         let area : u64 = 144;
//         let year : u64 = 10;
//         let price: u64 = 1000;
//         let distance: u64 = 50000;

//         // create a house for test_address1
//         helper_create_house(
//             scenario,
//             TEST_ADDRESS1,
//             location,
//             area,
//             year,
//             price
//             );
//         // create a land for test_address1
//         helper_create_land(
//             scenario,
//             TEST_ADDRESS1,
//             location,
//             area,
//             price
//         );
//         // create a shop for test_address1
//         helper_create_shop(
//             scenario,
//             TEST_ADDRESS1,
//             location,
//             area,
//             year,
//             price
//         );
//         // create a car for test_address1
//         helper_create_car(
//             scenario,
//             TEST_ADDRESS1,
//             model,
//             year,
//             color,
//             distance,
//             price
//         );
//     }
//     public fun helper_approve_house(
//         scenario: &mut Scenario
//     ) {
//         next_tx(scenario, ADMIN);
//         {
//             let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//             let asset_share = ts::take_shared<ListedAssets>(scenario);
//             let approve: bool = true;
//             let id = ao::test_get_house_id(&asset_share, 0); 
//             ao::approve_house(&admin_cap, &mut asset_share, id, approve);

//             ts::return_shared(asset_share);
//             ts::return_to_sender(scenario, admin_cap);
//         };
//     }

//     // public fun helper_approve_car(
//     //     scenario: &mut Scenario
//     // ) {
//     //    // owner must approve that Car
//     //     next_tx(scenario, ADMIN);
//     //     {
//     //         let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//     //         let asset_share = ts::take_shared<ListedAssets>(scenario); 
//     //         ao::approve_car(&admin_cap, &mut asset_share, TEST_ADDRESS1);

//     //         ts::return_shared(asset_share);
//     //         ts::return_to_sender(scenario, admin_cap);
//     //     };
//     // }

//     // public fun helper_approve_shop(
//     //     scenario: &mut Scenario
//     // ) {
//     //     // owner must approve that Land
//     //     next_tx(scenario, ADMIN);
//     //     {
//     //         let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//     //         let asset_share = ts::take_shared<ListedAssets>(scenario); 
//     //         ao::approve_shop(&admin_cap, &mut asset_share, TEST_ADDRESS1);

//     //         ts::return_shared(asset_share);
//     //         ts::return_to_sender(scenario, admin_cap);
//     //     };
//     // }
    
//     // public fun helper_approve_land(
//     //     scenario: &mut Scenario
//     // ) {
//     //     // owner must approve that Shop
//     //     next_tx(scenario, ADMIN);
//     //     {
//     //         let admin_cap = ts::take_from_sender<AdminCap>(scenario);
//     //         let asset_share = ts::take_shared<ListedAssets>(scenario); 
//     //         ao::approve_land(&admin_cap, &mut asset_share, TEST_ADDRESS1);

//     //         ts::return_shared(asset_share);
//     //         ts::return_to_sender(scenario, admin_cap);
//     //     };
//     // }

//     // public fun helper_approve_all(scenario: &mut Scenario) {
//     //     helper_approve_car(scenario);
//     //     helper_approve_house(scenario);
//     //     helper_approve_land(scenario);
//     //     helper_approve_shop(scenario);
//     // }

//     public fun helper_add_table_house(scenario: &mut Scenario) {
//         //Add ListedAssets to table
//         next_tx(scenario, TEST_ADDRESS1);
//         {
//             let asset_share = ts::take_shared<ListedAssets>(scenario);
//             let house = ts::take_from_sender<House>(scenario);
            
//             ao::add_house_table(&mut asset_share, house);

//             ts::return_shared(asset_share);
//         };
//     }
    
//     public fun helper_add_all_table(scenario: &mut Scenario) {

//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
//             let house = ts::take_from_sender<House>(scenario);
//             ao::add_house_table(&mut listed_asset_shared, house);

//             ts::return_shared(listed_asset_shared);
//         };
//         //Add ListedAssets to table
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
//             let car = ts::take_from_sender<Car>(scenario);
//             ao::add_car_table(&mut listed_asset_shared, car);

//             ts::return_shared(listed_asset_shared);
//         };
//          //Add ListedAssets to table
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
//             let land = ts::take_from_sender<Land>(scenario);
//             ao::add_land_table(&mut listed_asset_shared, land);

//             ts::return_shared(listed_asset_shared);
//         };
//         //Add ListedAssets to table
//         next_tx(scenario, TEST_ADDRESS1);
//         {   
//             let listed_asset_shared = ts::take_shared<ListedAssets>(scenario);
//             let shop = ts::take_from_sender<Shop>(scenario);
//             ao::add_shop_table(&mut listed_asset_shared, shop);

//             ts::return_shared(listed_asset_shared);
//         };
//     }

    


    
//     public fun init_test_helper() : ts::Scenario{

//        let owner: address = @0xA;
//        let scenario_val = ts::begin(owner);
//        let scenario = &mut scenario_val;
 
//        {
//            test_init(ts::ctx(scenario));
//        };
//        {
//           return_init_lira(ts::ctx(scenario));
//        };
//        scenario_val
// }

// }