// CRUD Module 
// define asset types  > House Car Land 
// define share object for listedtypes allow types 
// The admin should be able to add new transfer policy to share object
// create update and read and destroye 
module notary::assets_type {
    use std::string::{String};
    use std::vector;
   // use std::option::{Option};
   // use std::type_name::{TypeName};
   // use std::debug;

    use sui::tx_context::{Self, TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::bag::{Self};
    use sui::table::{Self, Table}; 
    use sui::coin::{Coin};
    use sui::sui::SUI;
    
    // use notary::lira_stable_coin::{LIRA_STABLE_COIN};

     use notary::assets::{Self, Asset};

    // =================== Errors ===================

    // It can be only one type 
    const ERROR_INVALID_TYPE: u64 = 1;
    //const ERROR_NOT_APPROVED: u64 = 2;
    const ERROR_NOT_KIOSK_OWNER: u64 = 3;

    // =================== Structs ===================

    // share object 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
        kiosk_caps: Table<ID, KioskOwnerCap>,
        asset_id: vector<ID>, // FIXME: Delete me !!
        kiosk_id: vector<ID>  // FIXME: Delete me !!
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
            kiosk_caps: table::new<ID, KioskOwnerCap>(ctx),
            asset_id: vector::empty(),  // FIXME: Delete me !!
            kiosk_id: vector::empty()  // FIXME: Delete me !!
        });
        // define the publisher
        let publisher_ = package::claim<ASSETS_TYPE>(otw, ctx);
        // wrap the publisher and share.
        transfer::share_object(AssetsTypePublisher {
            id: object::new(ctx),
            publisher: publisher_
        });
        // transfer the admincap
        transfer::transfer(AdminCap{id: object::new(ctx)}, tx_context::sender(ctx));
    }
    // =================== Functions ===================

    // create types for mint an nft 
    public fun create_type(_: &AdminCap, share: &mut ListedTypes, type: String) {
        assert!(vector::contains(&share.types, &type) == false, ERROR_INVALID_TYPE);
        vector::push_back(&mut share.types, type);
    }
    // Users will create kiosk and protocol will store these caps in share object
    public fun create_kiosk(share: &mut ListedTypes, ctx: &mut TxContext) {
        let(kiosk, kiosk_cap) = kiosk::new(ctx);

        vector::push_back(&mut share.kiosk_id, object::id(&kiosk_cap)); // FIXME: Delete me !!

        transfer::public_share_object(kiosk);

        table::add(&mut share.kiosk_caps, object::id(&kiosk_cap), kiosk_cap);
    }
    // the kiosk owner should add extensions
    public fun add_extensions(
        _: &AdminCap,
        share: &ListedTypes,
        self: &mut Kiosk,
        id: ID,
        permissions: u128,
        ctx: &mut TxContext
        ) { 
            let kiosk_cap = table::borrow(&share.kiosk_caps, id); 
            let witness = NotaryKioskExtWitness {};

            ke::add<NotaryKioskExtWitness>(witness, self, kiosk_cap, permissions, ctx);
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
    // admin can create new_policy for sales or renting operations. 
    public fun new_policy(_: &AdminCap, publish: &AssetsTypePublisher, ctx: &mut TxContext ) {
        // set the publisher
        let publisher_ = &publish.publisher;
        // create an transfer_policy and tp_cap
        let (transfer_policy, tp_cap) = policy::new<Asset>(publisher_, ctx);
        // transfer the objects 
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    } 
    // admin can approve the asset. Means that it will be removing from extensions and placing in kiosk 
    public fun approve(_: &AdminCap, kiosk: &mut Kiosk, policy: &TransferPolicy<Asset>, id: ID) {
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(NotaryKioskExtWitness{}, kiosk);
        let asset = bag::remove<ID, Asset>(bag_, id);
        // set the asset.approve to true 
        assets::approve_asset(&mut asset);

        ke::place<NotaryKioskExtWitness, Asset>(NotaryKioskExtWitness{}, kiosk, asset, policy);  
    }
    // User1 has to list with purchase so he can send the person who wants to buy him own asset
    public fun list_with_purchase(
        share: &ListedTypes,
        kiosk: &mut Kiosk,
        cap_id: ID,
        asset_id: ID,
        price: u64,
        ctx: &mut TxContext) {
            // check the kiosk owner
            assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            // set the kiosk cap 
            let kiosk_cap = table::borrow(&share.kiosk_caps, cap_id);

            let purch_cap = kiosk::list_with_purchase_cap<Asset>(
                kiosk,
                kiosk_cap,
                asset_id,
                price,
                ctx
            );
            transfer::public_transfer(purch_cap, sender(ctx));
        }
    // User2 can buy another person assets and it has to be directy placed in his kiosk. 
    public fun purchase_with_list(
        kiosk1: &mut Kiosk,
        kiosk2: &mut Kiosk,
        share: &ListedTypes,
        policy: &TransferPolicy<Asset>,
        purchase_cap: PurchaseCap<Asset>,
        kiosk_cap: ID,
        payment: Coin<SUI>,
        ctx: &mut TxContext
        ) {
            let (item, request) = kiosk::purchase_with_cap(
                kiosk1,
                purchase_cap,
                payment
                );
            policy::confirm_request(policy, request);
            assert!(kiosk::owner(kiosk2) == sender(ctx), ERROR_NOT_KIOSK_OWNER);

            let kiosk_cap = table::borrow(&share.kiosk_caps, kiosk_cap);
            kiosk::place(kiosk2, kiosk_cap, item);
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
}
