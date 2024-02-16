// CRUD Module 
// define asset types  > House Car Land 
// define share object for listedtypes allow types 
// The admin should be able to add new transfer policy to share object
// create update and read and destroye 
module notary::assets_type {
    use std::string::{String};
    use std::vector;
    use std::type_name::{TypeName};
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::vec_set::{Self, VecSet};
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap};
    //use sui::kiosk::{Self, Kiosk, KioskOwnerCap};

    // use notary::lira_stable_coin::{LIRA_STABLE_COIN};

     use notary::assets::{Self, Asset};

    // =================== Errors ===================
    // It can be only one type 
    const ERROR_INVALID_TYPE: u64 = 1;

    // =================== Structs ===================

    // share object 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
    }
    
    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }
    // one time witness 
    struct ASSETS_TYPE has drop {}

    /// The "Rule" witness to authorize the policy.
    struct Rule has drop {}

    /// Configuration for the `Approve by admin`.
    /// It holds the boolean for asset.
    /// There can't be any sales if the asset is not approved.
    struct Approve has store, drop {
        approved: bool
    }

    // =================== Initializer ===================

    fun init(otw: ASSETS_TYPE, ctx: &mut TxContext) {
        // define the ListedTypes Share object 
        transfer::share_object(ListedTypes{
            id:object::new(ctx),
            types: vector::empty()
        });
        let publisher = package::claim(otw, ctx);
        let (transfer_policy, tp_cap) = tp::new<Asset>(&publisher, ctx);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));

        transfer::public_share_object(transfer_policy);
    }

    public fun create_type(_: &AdminCap, share: &mut ListedTypes, type: String) {
        assert!(vector::contains(&share.types, &type) == false, ERROR_INVALID_TYPE);
        vector::push_back(&mut share.types, type);
    }

    public fun add_rule<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
        approved: bool
    ) {
        tp::add_rule(Rule {}, policy, cap, Approve { approved })
    }





















}