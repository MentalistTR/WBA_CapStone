// module rules::loan_duration {
//     use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap, TransferRequest};
//     use sui::kiosk::{Kiosk};
//     use sui::tx_context::{Self, TxContext};

//     use notary::assets::{Asset};

//     //const ERROR_NOT_IN_KIOSK :u64 = 0;

//     // one time witness for rules 
//     struct Rule has drop {}

//     struct Config has store, drop {
//         minumum_duration: u64,
//         maximum_duration: u64
//     }

//     public fun add<T>(
//         policy: &mut TransferPolicy<T>,
//         cap: &TransferPolicyCap<T>,
//         min: u64,
//         max: u64
//     ) {
//         policy::add_rule(Rule {}, policy, cap, Config {minumum_duration: min, maximum_duration: max})
//     }

//     public fun prove<T>(
//         policy: &TransferPolicy<T>,
//         request: &mut TransferRequest<T>,
//         kiosk: &Kiosk,
      
//         ) {
//         let config: &Config = policy::get_rule(Rule {}, policy);

//         assert!()
       
//         policy::add_receipt(Rule {}, request);
//     }

// }