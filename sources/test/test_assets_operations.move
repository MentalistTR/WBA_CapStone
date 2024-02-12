#[test_only]
module notary::test_ListedAssetss_operations {
    use sui::transfer;
    use sui::coin::{Self, mint_for_testing};
    use sui::test_scenario::{Self as ts, next_tx};
    use sui::test_utils::{assert_eq};

    use std::string::{Self,String};

    use notary::helpers::{Self, init_test_helper, helper_create_account};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{Self, };
    
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




        ts::end(scenario_test);
    }










}