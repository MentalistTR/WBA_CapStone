#[test_only]
module notary::helpers {
    use sui::tx_context::{Self,TxContext};
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::test_utils::{assert_eq};


    use notary::assets_operation::{test_init};
    use notary::lira_stable_coin::{return_init_lira};














    
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