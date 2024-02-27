module notary::assets_rules {
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::kiosk::{Kiosk};

    use notary::assets::{Asset};

    //const ERROR_NOT_IN_KIOSK :u64 = 0;

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