module rules::time_duration {
    use sui::transfer_policy::{Self as policy, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::kiosk::{Kiosk};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Clock, timestamp_ms}; 
    
    const ERROR_INVALID_DURATION :u64 = 0;

    // one time witness for rules 
    struct Rule has drop {}

    struct Config has store, drop {}

    public fun add<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
    ) {
        policy::add_rule(Rule {}, policy, cap, Config {})
    }

    public fun prove<T>(
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        clock: &Clock,
        contract_end: u64,
        contract_start: u64,
        contract_rental: u64
    ) {
        let config: &Config = policy::get_rule(Rule {}, policy);

        assert!(timestamp_ms(clock) >= contract_end || (timestamp_ms(clock) - (contract_start)) / ((86400 * 30)) + 1 > contract_rental, ERROR_INVALID_DURATION);
       
        policy::add_receipt(Rule {}, request);
    }

}