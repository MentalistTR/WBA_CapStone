#[test_only]
module notary::test_assets_operations {
    use sui::transfer;
    use sui::coin::{Self, Coin, mint_for_testing, CoinMetadata};
    use sui::tx_context::{Self,TxContext};
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::test_utils::{assert_eq};

    use notary::helpers::{init_test_helper};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets_operation::{Self as ap, Data, Asset, House, Land, Car, Shop, Sales};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;
    const TEST_ADDRESS3: address = @0xD;
    const TEST_ADDRESS4: address = @0xE;

    public fun test_create() {
        let scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        next_tx(scenario, ADMIN);
        {

        }




    }























}