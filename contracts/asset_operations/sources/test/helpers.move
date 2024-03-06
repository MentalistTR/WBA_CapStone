#[test_only]
module notary::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
 
    use std::string::{Self};
    // use std::option::{Self};
    // use std::debug;


    use notary::lira::{return_init_lira};

    use notary::assets_type::{Self as at, AdminCap, ListedTypes, AssetsTypePublisher, test_init};
    use notary:: assets_renting::{test_renting_init};

    const ADMIN: address = @0xA;
    
    public fun helper_add_types(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            let listed_shared = ts::take_shared<ListedTypes>(scenario);
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
     
            let type1 = string::utf8(b"House");
            let type2 = string::utf8(b"Car");
            let type3 = string::utf8(b"Shop");
            let type4 = string::utf8(b"Land");

            at::create_type(&admin_cap, &mut listed_shared, type1);
            at::create_type(&admin_cap, &mut listed_shared, type2);
            at::create_type(&admin_cap, &mut listed_shared, type3);
            at::create_type(&admin_cap, &mut listed_shared, type4);

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(listed_shared);
        };
    }
    
    public fun helper_new_policy<T>(scenario: &mut Scenario) {
        next_tx(scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(scenario);
            let publisher_share = ts::take_shared<AssetsTypePublisher>(scenario);
    
            at::new_policy<T>(&admin_cap, &publisher_share, ts::ctx(scenario));

            ts::return_to_sender(scenario, admin_cap);
            ts::return_shared(publisher_share);
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
            test_renting_init(ts::ctx(scenario));
       };
       {
            return_init_lira(ts::ctx(scenario));
       };
       scenario_val
    }

}
