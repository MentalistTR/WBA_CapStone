#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::transfer;
    use sui::coin::{mint_for_testing};
    use sui::test_utils::{assert_eq};

    use std::string::{Self, String};
    


    use notary::assets_operation::{Self as ao, test_init, Account, Asset};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN, return_init_lira};

    use notary::assets::{
        Self, House, Land, Car, Shop, Sales, return_house_bool, return_car_bool,
        return_land_bool, return_shop_bool
        };

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
        sender: address,
        test_location: vector<u8>,
        test_area: u64,
        test_year: u64,
        test_price: u64
        ) {

        next_tx(scenario, sender);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(test_location);
            let area: u64 = test_area;
            let year: u64 = test_year;
            let price: u64 = test_price;

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
    }

     public fun helper_create_shop(
        scenario: &mut Scenario,
        sender: address,
        test_location: vector<u8>,
        test_area: u64,
        test_year: u64,
        test_price: u64
        ) {

        next_tx(scenario, sender);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(test_location);
            let area: u64 = test_area;
            let year: u64 = test_year;
            let price: u64 = test_price;

            ao::create_shop(
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

    public fun helper_create_land(
        scenario: &mut Scenario,
        sender: address,
        test_location: vector<u8>,
        test_area: u64,
        test_price: u64
        ) {

        next_tx(scenario, sender);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let location = string::utf8(test_location);
            let area: u64 = test_area;
            let price: u64 = test_price;

            ao::create_land(
                &mut asset_share,
                &mut account,
                location,
                area,
                price,
                ts::ctx(scenario)
             );
            ts::return_to_sender(scenario, account);
            ts::return_shared(asset_share);
        };
    }

    public fun helper_create_car(
        scenario: &mut Scenario,
        sender: address,
        test_model: vector<u8>,
        test_year: u64,
        test_color: vector<u8>,
        test_distance: u64,
        test_price: u64
        ) {

        next_tx(scenario, sender);
        {   
            // define variables for create house object
            let asset_share = ts::take_shared<Asset>(scenario);
            let account = ts::take_from_sender<Account>(scenario);
            let test_model = string::utf8(test_model);
            let test_color = string::utf8(test_color);
         
        
            let price: u64 = test_price;

            ao::create_car(
                &mut asset_share,
                &mut account,
                test_model,
                test_year,
                test_color,
                test_distance,
                test_price,
                ts::ctx(scenario)
             );
            ts::return_to_sender(scenario, account);
            ts::return_shared(asset_share);
        };
    }

    public fun helper_approve_house(
        scenario: &mut Scenario
    ) {

        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<House>(scenario);
            // lets call house bool 
            let approve = return_house_bool(&mut asset);
            // bool must be equal to true 
            assert_eq(approve, true);
            ts::return_to_sender(scenario, asset);
        };
    }

    public fun helper_approve_car(
        scenario: &mut Scenario
    ) {

        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<Car>(scenario);
            // lets call house bool 
            let approve = return_car_bool(&mut asset);
            // bool must be equal to true 
            assert_eq(approve, true);
            ts::return_to_sender(scenario, asset);
        };
    }

    public fun helper_approve_shop(
        scenario: &mut Scenario
    ) {

        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<Shop>(scenario);
            // lets call house bool 
            let approve = return_shop_bool(&mut asset);
            // bool must be equal to true 
            assert_eq(approve, true);
            ts::return_to_sender(scenario, asset);
        };
    }
    
    public fun helper_approve_land(
        scenario: &mut Scenario
    ) {

        next_tx(scenario, TEST_ADDRESS1);
        {   
            let asset = ts::take_from_sender<Land>(scenario);
            // lets call house bool 
            let approve = return_land_bool(&mut asset);
            // bool must be equal to true 
            assert_eq(approve, true);
            ts::return_to_sender(scenario, asset);
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