// CRUD Module 
// define asset types  > House Car Land 
// define share object for listedtypes allow types 
// The admin should be able to add new transfer policy to share object
// create update and read and destroye 
module notary::assets_type {
    use std::string::{String};
    use std::vector;
   // use std::type_name::{TypeName};
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID};
    use sui::transfer;
   // use sui::balance::{Self, Balance};
   // use sui::coin::{Self, Coin};
   // use sui::vec_set::{Self, VecSet};
    use sui::package::{Self};
   // use sui::transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::kiosk_extension::{Self as ke};

    // use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    // use notary::assets::{Self, Asset};

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
        transfer::public_transfer(publisher, tx_context::sender(ctx));

        transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx));
        // define kiosk and kiosk ownercap 
        // let(kiosk, kiosk_cap) = kiosk::new(ctx);
        // transfer::public_share_object(kiosk);
        // transfer::public_transfer(kiosk_cap, tx_context::sender(ctx));
    }
    // create types for mint an nft 
    public fun create_type(_: &AdminCap, share: &mut ListedTypes, type: String) {
        assert!(vector::contains(&share.types, &type) == false, ERROR_INVALID_TYPE);
        vector::push_back(&mut share.types, type);
    }

    // admin should create a kiosk for users
    public fun create_kiosk(_: &AdminCap, ctx: &mut TxContext) {
        let(kiosk, kiosk_cap) = kiosk::new(ctx);
        transfer::public_share_object(kiosk);
        transfer::public_transfer(kiosk_cap, tx_context::sender(ctx));
    }
    // only admin can add extensions to kiosk
    public fun add_extensions<Ext: drop>(
        _: &AdminCap, 
        ext: Ext,
        self: &mut Kiosk,
        cap: &KioskOwnerCap,
        permissions: u128,
        ctx: &mut TxContext
        ) {
            ke::add(ext, self, cap, permissions, ctx);
        }
    


    










    // public fun add_rule<T>(
    //     policy: &mut TransferPolicy<T>,
    //     cap: &TransferPolicyCap<T>,
    //     approved: bool
    // ) {
    //     tp::add_rule(Rule {}, policy, cap, Approve { approved })
    // }

    // public fun prove<T>(
    //     policy: &mut TransferPolicy<T>,
    //     request: &mut TransferRequest<T>
    // ) {
    //     let approve: &Approve = tp::get_rule(Rule {}, policy);

    //     assert!(tp::paid(request) == approve.approved, ERROR_INVALID_TYPE);

    //     tp::add_receipt(Rule {}, request)
    // }


    #[test_only]
    // call the init function
    public fun test_init(ctx: &mut TxContext) {
        init(ASSETS_TYPE {}, ctx);
    }



















}