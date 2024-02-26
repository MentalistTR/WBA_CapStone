module notary::assets_rules {
    use std::string::{String};
    use std::vector;
    use std::option::{Option};

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::bag::{Self, Bag}; 
    use sui::dynamic_object_field::{Self as dof};

    use notary::assets_type::{AdminCap};
    use notary::assets::{Asset};

    const ERROR_NOT_IN_KIOSK :u64 = 0;

    // one time witness for rules 
    struct Rule has drop {}

    struct Config has store, drop {renting: bool}

    public fun add_rule<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
    ) {
        policy::add_rule(Rule {}, policy, cap, Config {renting: false})
    }

    public fun prove<T>(
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        kiosk: &Kiosk,
        asset: &Asset
          ) {
        let config: &Config = policy::get_rule(Rule {}, policy);
       
        policy::add_receipt(Rule {}, request);
    }



}