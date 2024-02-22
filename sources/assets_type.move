// CRUD Module 
// define asset types  > House Car Land 
// define share object for listedtypes allow types 
// The admin should be able to add new transfer policy to share object
// create update and read and destroye 
module notary::assets_type {
    use std::string::{String};
    use std::vector;
    use std::option::{Option};
   // use std::type_name::{TypeName};
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as tp, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::bag::{Self, Bag}; 
    use sui::dynamic_object_field::{Self as dof};
    
    // use notary::lira_stable_coin::{LIRA_STABLE_COIN};

     use notary::assets::{Self, Asset};

    // =================== Errors ===================

    // It can be only one type 
    const ERROR_INVALID_TYPE: u64 = 1;
    const ERROR_NOT_APPROVED: u64 = 2;

    // =================== Structs ===================

    // share object 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
        asset_id: vector<ID> // FIXME: Delete me !!
    }
    
    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }
    // one time witness 
    struct ASSETS_TYPE has drop {}

    /// Publisher capability object
    struct AssetsTypePublisher has key { id: UID, publisher: Publisher }

    // witness for kiosk
    struct NotaryKioskExtWitness has drop {}

    // =================== Initializer ===================

    fun init(otw: ASSETS_TYPE, ctx: &mut TxContext) {
        // define the ListedTypes Share object 
        transfer::share_object(ListedTypes{
            id:object::new(ctx),
            types: vector::empty(),
            asset_id: vector::empty()
        });
        // define the publisher
        let publisher_ = package::claim<ASSETS_TYPE>(otw, ctx);
        // define the transfer_policy and tp_cap 
        let (transfer_policy, tp_cap) = tp::new<Asset>(&publisher_, ctx);
        
        transfer::share_object(AssetsTypePublisher {
            id: object::new(ctx),
            publisher: publisher_
        });
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    }
    // =================== Functions ===================

    // create types for mint an nft 
    public fun create_type(_: &AdminCap, share: &mut ListedTypes, type: String) {
        assert!(vector::contains(&share.types, &type) == false, ERROR_INVALID_TYPE);
        vector::push_back(&mut share.types, type);
    }

    // admin should create a kiosk for users
    public fun create_kiosk(ctx: &mut TxContext) {
        let(kiosk, kiosk_cap) = kiosk::new(ctx);

        transfer::public_share_object(kiosk);
        transfer::public_transfer(kiosk_cap, tx_context::sender(ctx));
    }
    // the kiosk owner should add extensions
    public fun add_extensions(
        self: &mut Kiosk,
        cap: &KioskOwnerCap,
        permissions: u128,
        ctx: &mut TxContext
        ) {
            let witness = NotaryKioskExtWitness {};
            ke::add<NotaryKioskExtWitness>(witness, self, cap, permissions, ctx);
        }
    // Users can create asset 
    public fun create_asset(
        type: String,
        price: u64,
        shared: &mut ListedTypes,
        kiosk: &mut Kiosk,
        ctx :&mut TxContext,
        ) {
        assert!(!vector::contains(&shared.types, &type), ERROR_INVALID_TYPE);
        let asset = assets::create_asset(type, price, ctx);

        vector::push_back(&mut shared.asset_id, assets::borrow_id(&asset));  // FIXME: Delete me  !!!! 

        let witness= NotaryKioskExtWitness {};
        place_in_extension(kiosk, asset);  
    }
    // admin can approve the asset. Means that it will be removing from extensions and placing in kiosk 
    public fun approve(_: &AdminCap, kiosk: &mut Kiosk, policy: &TransferPolicy<Asset>, id: ID) {
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(NotaryKioskExtWitness{}, kiosk);
        let asset = bag::remove<ID, Asset>(bag_, id);
        // set the asset.approve to true 
        assets::approve_asset(&mut asset);

        ke::place<NotaryKioskExtWitness, Asset>(NotaryKioskExtWitness{}, kiosk, asset, policy);  
    }
    public fun add_kiosk(_: &KioskOwnerCap, kiosk: &mut Kiosk, asset: Asset) {
        assert!(assets::is_approved(&asset), ERROR_NOT_APPROVED);
        // set the approve false
        assets::disable_approve(&mut asset);
       // place to in_extension
        place_in_extension(kiosk, asset);
    }

    // =================== Helper Functions ===================

    // Helper function for when the asset created it will be automatically in the extension
    fun place_in_extension(
        kiosk: &mut Kiosk,
        asset: Asset,
    ) {
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(NotaryKioskExtWitness{}, kiosk);
        bag::add<ID, Asset>(bag_, object::id(&asset), asset);
    }
    // =================== Test Only ===================

    #[test_only]
    // call the init function
    public fun test_init(ctx: &mut TxContext) {
        init(ASSETS_TYPE {}, ctx);
    }
     #[test_only]
    // call the init function
    public fun test_witness() : NotaryKioskExtWitness  {
        let witness = NotaryKioskExtWitness {};
        witness
    }
    #[test_only]
     // return id of asset 
     public fun get_id(shared: &ListedTypes, index: u64) : ID {
        let asset_id = vector::borrow(&shared.asset_id, index);
        *asset_id
     }
    #[test_only]
    public fun get_dynamic_field(kiosk: &Kiosk, field: u64) : Option<ID> {
        let kiosk_id = kiosk::uid(kiosk);
        let id = dof::id(kiosk_id, field);
        id
    }
}
