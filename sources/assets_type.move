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

    use notary::assets::{Self, Asset};

    // =================== Errors ===================

    // It can be only one type 
    const ERROR_INVALID_TYPE: u64 = 1;
    const ERROR_NOT_APPROVED: u64 = 2;
    const ERROR_NOT_KIOSK_OWNER: u64 = 3;

    // =================== Structs ===================

    // share object 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
        kiosk_caps: Table<ID, KioskOwnerCap>,
        purchase_cap: Table<ID, PurchaseCap<Asset>>
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
            purchase_cap: table::new<ID, PurchaseCap<Asset>>(ctx), 
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

        transfer::public_share_object(kiosk);

        table::add(&mut share.kiosk_caps, object::id(&kiosk_cap), kiosk_cap);
    }

    // Users can create asset
    public fun create_asset(
        type: String,
        price: u64,
        shared: &mut ListedTypes,
        policy: &TransferPolicy<Asset>,
        kiosk: &mut Kiosk,
        cap_id: ID,
        ctx :&mut TxContext,
        ) {
            assert!(!vector::contains(&shared.types, &type), ERROR_INVALID_TYPE);

            let asset = assets::create_asset(type, price, ctx);
            let kiosk_cap = table::borrow(&shared.kiosk_caps, cap_id);

            kiosk::lock(kiosk, kiosk_cap, policy, asset);  
    }
    public fun new_property(
        share: &ListedTypes,
        kiosk: &mut Kiosk,
        cap_id: ID,
        item_id: ID,
        property_name: String,
        property: String) {

            let kiosk_cap = table::borrow(&share.kiosk_caps, cap_id);
            let item = kiosk::borrow_mut<Asset>(kiosk, kiosk_cap, item_id);
            // add the new property 
            assets::new_property(item, property_name, property);
            // if the user change asset propertys. It should be removed.
            assets::disapprove_asset(item);
    }

    // admin can create new_policy for sales or renting operations. 
    public fun new_policy(_: &AdminCap, publish: &AssetsTypePublisher, ctx: &mut TxContext ) {
        // set the publisher
        let publisher = get_publisher(publish);
        // create an transfer_policy and tp_cap
        let (transfer_policy, tp_cap) = policy::new<Asset>(publisher, ctx);
        // transfer the objects 
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    }

    // admin must approve the asset
    public fun approve(_: &AdminCap, share: &ListedTypes, kiosk: &mut Kiosk, cap_id: ID, item: ID) {
        // take the kiosk cap from table 
        let kiosk_cap = table::borrow(&share.kiosk_caps, cap_id);
        // take the item from kiosk
        let item = kiosk::borrow_mut<Asset>(kiosk, kiosk_cap, item);
        // approve the asset.
        assets::approve_asset(item);
    }

    // User1 has to list with purchase so he can send the person who wants to buy him own asset
    public fun list_with_purchase(
        share: &mut ListedTypes,
        kiosk: &mut Kiosk,
        cap_id: ID,
        asset_id: ID,
        price: u64,
        ctx: &mut TxContext) {
            // check the kiosk owner
            assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            // set the kiosk cap 
            let kiosk_cap = table::borrow(&share.kiosk_caps, cap_id);
            // borrow the asset 
            let asset = kiosk::borrow<Asset>(kiosk, kiosk_cap, asset_id);
            assert!(assets::is_approved(asset), ERROR_NOT_APPROVED);

            let purch_cap = kiosk::list_with_purchase_cap<Asset>(
                kiosk,
                kiosk_cap,
                asset_id,
                price,
                ctx
            );
            // store the purchase_cap in the protocol
            table::add(&mut share.purchase_cap, object::id(&purch_cap), purch_cap);
        }

    // User2 can buy another person assets and it has to be directy placed in his kiosk. 
    public fun purchase_with_cap(
        kiosk1: &mut Kiosk,
        kiosk2: &mut Kiosk,
        share: &mut ListedTypes,
        policy: &TransferPolicy<Asset>,
        purchase_cap: ID,
        kiosk_cap: ID,
        payment: Coin<SUI>,
        ctx: &mut TxContext
        ) {
            // remove the purchase_cap from table 
            let purchase_cap = table::remove(&mut share.purchase_cap, purchase_cap);
            // purchase the asset from kiosk
            let (item, request) = kiosk::purchase_with_cap(
                kiosk1,
                purchase_cap,
                payment
                );
            // confirm the request. Destroye the hot potato
            policy::confirm_request(policy, request);
            // be sure that sender is the owner of kiosk
            assert!(kiosk::owner(kiosk2) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            // place the asset into the kiosk
            let kiosk_cap = table::borrow(&share.kiosk_caps, kiosk_cap);
            kiosk::place(kiosk2, kiosk_cap, item);
        }
    // Kiosk owner's can withdraw the profits
    public fun withdraw_profits(
        kiosk: &mut Kiosk,
        shared: &ListedTypes,
        cap_id: ID,
        amount: Option<u64>,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        // check the owner of kiosk
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // set the kiosk_cap
        let kiosk_cap = table::borrow(&shared.kiosk_caps, cap_id);
        // take profits from kiosk
        let profits = kiosk::withdraw(kiosk, kiosk_cap, amount, ctx);

        profits
    }

    // =================== Helper Functions ===================
    
    // return the publisher
     public fun get_publisher(shared: &AssetsTypePublisher) : &Publisher {
        &shared.publisher
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
    // call the init function
    public fun get_kiosk_cap(share: &ListedTypes, id: ID) : &KioskOwnerCap  {
       let cap = table::borrow(&share.kiosk_caps, id);
       cap   
    }

}
