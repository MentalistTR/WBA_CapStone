// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Description:
/// This module defines a Rule which requires a payment on a purchase.
/// The payment amount can be either a fixed amount (min_amount) or a
/// percentage of the purchase price (amount_bp). Or both: the higher
/// of the two is used.
///
/// Configuration:
/// - amount_bp - the percentage of the purchase price to be paid as a
/// fee, denominated in basis points (100_00 = 100%, 1 = 0.01%).
/// - min_amount - the minimum amount to be paid as a fee if the relative
/// amount is lower than this setting.
///
/// Use cases:
/// - Percentage-based Royalty fee for the creator of the NFT.
/// - Fixed commission fee on a trade.
/// - A mix of both: the higher of the two is used.
///
/// Notes:
/// - To use it as a fixed commission set the `amount_bp` to 0 and use the
/// `min_amount` to set the fixed amount.
/// - To use it as a percentage-based fee set the `min_amount` to 0 and use
/// the `amount_bp` to set the percentage.
/// - To use it as a mix of both set the `min_amount` to the min amount
/// acceptable and the `amount_bp` to the percentage of the purchase price.
/// The higher of the two will be used.
///
module rules::royalty_rule {
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };
    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use rules::lira::{LIRA};

    /// The `amount_bp` passed is more than 100%.
    const EIncorrectArgument: u64 = 0;
    /// The `Coin` used for payment is not enough to cover the fee.
    const EInsufficientAmount: u64 = 1;

    /// Max value for the `amount_bp`.
    const MAX_BPS: u16 = 10_000;

    /// The "Rule" witness to authorize the policy.
    struct Rule has drop {}

    /// share object that we keep fees
    struct NotaryFee has key {
        id: UID,
        balance: Balance<LIRA>
    }
    // Only owner of this module can access it.
    struct OwnerCap has key {
        id: UID,
    }    

    fun init(ctx: &mut TxContext) {
        transfer::share_object(NotaryFee{
            id: object::new(ctx),
            balance: balance::zero()
        });
        // transfer the admincap
        transfer::transfer(OwnerCap{id: object::new(ctx)}, sender(ctx));
    }

    /// Configuration for the Rule. The `amount_bp` is the percentage
    /// of the transfer amount to be paid as a royalty fee. The `min_amount`
    /// is the minimum amount to be paid if the percentage based fee is
    /// lower than the `min_amount` setting.
    ///
    /// Adding a mininum amount is useful to enforce a fixed fee even if
    /// the transfer amount is very small or 0.
    struct Config has store, drop {
    }

    /// Creator action: Add the Royalty Rule for the `T`.
    /// Pass in the `TransferPolicy`, `TransferPolicyCap` and the configuration
    /// for the policy: `amount_bp` and `min_amount`.
    public fun add<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
    ) {
        policy::add_rule(Rule {}, policy, cap, Config {})
    }

    // /// Buyer action: Pay the royalty fee for the transfer.
    public fun pay<T>(
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        notary: &mut NotaryFee,
        payment: Coin<LIRA>,
        ctx: &mut TxContext
    ) {
        let config: &Config = policy::get_rule(Rule {}, policy);
        // split 1 LIRA for notary fee
        let admin_coin = coin::split(&mut payment, 1000000000, ctx);
        // put the coin as a balance
        coin::put(&mut notary.balance,admin_coin,);
        // add receipt
        policy::add_receipt(Rule {}, request);
        // transfer the rest of lira to sender if it is exist
        assert!(coin::value(&payment) > 0, EInsufficientAmount);
        transfer::public_transfer(payment, sender(ctx));
    }

    public fun withdraw(_: &OwnerCap, notary: &mut NotaryFee, ctx: &mut TxContext)  {
        let balance_ = balance::withdraw_all(&mut notary.balance);
        let coin = coin::from_balance( balance_, ctx);
        transfer::public_transfer(coin, sender(ctx));
    }

    #[test_only]
    public fun return_royalty_init(ctx: &mut TxContext) {
    init( ctx);
    }
    #[test_only]
    public fun return_notary_fee(self: &NotaryFee) : u64 {
        let value = balance::value(&self.balance);
        value
    }
}