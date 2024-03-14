/// Assets Sales module is responsible for managing the Asset, Kiosk and their operations
/// 
/// There are five main operations in this module:
/// 
/// 1. Admin can creates types and transferpolicy
/// 2. Admin can approve any asset 
/// 3. Users can create kiosk and assets
/// 4. Users can make new property for their own assets.
/// 5. Users can rent theirs assets
module notary::assets_type {
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Option};

    use sui::tx_context::{Self, TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::table::{Self, Table}; 
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use sui::bag::{Self, Bag};
    use sui::balance::{Self, Balance};

    use notary::assets::{Self, Asset};

    use rules::lira::{LIRA};
    use rules::royalty_rule::{Self as rr, NotaryFee};

    friend notary::assets_renting;
    friend notary::assets_legacy;

    // =================== Errors ===================

    const ERROR_INVALID_TYPE: u64 = 1;
    const ERROR_NOT_APPROVED: u64 = 2;
    const ERROR_NOT_KIOSK_OWNER: u64 = 3;
    const ERROR_ASSET_IN_RENTING: u64 = 4;

    // =================== Structs ===================

    // ListedTypes is used to keep assets types, kiosk caps, purchaseCap and fees 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
        kiosk_caps: Table<address, KioskOwnerCap>,
        purchase_cap: Table<ID, PurchaseCap<Asset>>,
        balance: Balance<LIRA>
    }
    
    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }
    // one time witness 
    struct ASSETS_TYPE has drop {}

    // kiosk_extension witness
    struct NotaryKioskExtWitness has drop {}

    /// Publisher capability object
    struct AssetsTypePublisher has key { id: UID, publisher: Publisher }
    
    // =================== Initializer ===================

    fun init(otw: ASSETS_TYPE, ctx: &mut TxContext) {
        // define the ListedTypes Share object 
        transfer::share_object(ListedTypes{
            id:object::new(ctx),
            types: vector::empty(),
            kiosk_caps: table::new<address, KioskOwnerCap>(ctx),
            purchase_cap: table::new<ID, PurchaseCap<Asset>>(ctx),
            balance: balance::zero() 
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

    /// Creates a new Type for asset 
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we keep types data
    /// * `type` - defines the asset type 
    public fun create_type(_: &AdminCap, share: &mut ListedTypes, type: String) {
        assert!(!vector::contains(&share.types, &type), ERROR_INVALID_TYPE);
        vector::push_back(&mut share.types, type);
    }
    /// Creates a new policy for sales, renting operations 
    /// 
    /// # Arguments
    /// 
    /// * `publish` - the Publisher that we use to create policy
    public fun new_policy<T>(_: &AdminCap, publish: &AssetsTypePublisher, ctx: &mut TxContext ) {
        // set the publisher
        let publisher = get_publisher(publish);
        // create an transfer_policy and tp_cap
        let (transfer_policy, tp_cap) = policy::new<T>(publisher, ctx);
        // transfer the objects 
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    }

    /// Admin can approve any assset from user's kiosk
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we reach the users kioskownercaps
    /// * `kiosk` - defines the user's kiosk
    /// * `item` - defines the assets ID
    /// * `user` - defines the kiosk's owner address
    public fun approve(_: &AdminCap, share: &ListedTypes, kiosk: &mut Kiosk, item: ID, user: address) {
        // take the kiosk cap from table 
        let kiosk_cap = table::borrow(&share.kiosk_caps, user);
        // take the item from kiosk
        let item = kiosk::borrow_mut<Asset>(kiosk, kiosk_cap, item);
        // approve the asset.
        assets::approve_asset(item);
    }
    /// Users can create only 1 times kiosk.
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we keep the users kioskownercaps
    public fun create_kiosk(share: &mut ListedTypes, ctx: &mut TxContext) {
        let(kiosk, kiosk_cap) = kiosk::new(ctx);
        // define the witness
        let witness = NotaryKioskExtWitness {};
        // create and extension for using bag
        ke::add<NotaryKioskExtWitness>(witness, &mut kiosk, &kiosk_cap, 00, ctx);
        // share the kiosk
        transfer::public_share_object(kiosk); 
        // keep kiosk_cap in the protocol
        table::add(&mut share.kiosk_caps, sender(ctx), kiosk_cap);
    }

    /// Users can create any asset
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we check the type of asset
    /// * `kiosk` - defines the user's kiosk
    /// * `type` - defines the asset type 
    public fun create_asset(
        shared: &ListedTypes,
        kiosk: &mut Kiosk,
        type: String,
        ctx :&mut TxContext,
        ) {
            assert!(vector::contains(&shared.types, &type), ERROR_INVALID_TYPE);

            let asset = assets::create_asset(type, ctx);
            let kiosk_cap = table::borrow(&shared.kiosk_caps, sender(ctx));

            kiosk::place(kiosk, kiosk_cap, asset);  
    }
    /// Users can create any property for the asset
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we check the type of asset
    /// * `kiosk` - defines the user's kiosk
    /// * `item` - defines the assets ID
    public fun new_property(
        share: &ListedTypes,
        kiosk: &mut Kiosk,
        item_id: ID,
        property_name: String,
        property: String,
        ctx: &mut TxContext
        ) {
            // check the kiosk owner
            assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            let kiosk_cap = table::borrow(&share.kiosk_caps, sender(ctx));
            let item = kiosk::borrow_mut<Asset>(kiosk, kiosk_cap, item_id);
            // add the new property 
            assets::new_property(item, property_name, property);
            // if the user change asset propertys. It should be removed.
            assets::disapprove_asset(item);
    }

    /// Users can remove any property for the asset
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we check the type of asset
    /// * `kiosk` - defines the user's kiosk
    /// * `item` - defines the assets ID
    public fun remove_property(
        share: &ListedTypes,
        kiosk: &mut Kiosk,
        item_id: ID,
        property_name: String,
        ctx: &mut TxContext
        ) {
            // check the kiosk owner
            assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            let kiosk_cap = table::borrow(&share.kiosk_caps, sender(ctx));
            let item = kiosk::borrow_mut<Asset>(kiosk, kiosk_cap, item_id);
            // remove the property
            assets::remove_property(item, property_name);
            // if the user change asset propertys. It should be removed.
            assets::disapprove_asset(item);
    }

    /// Users can list the asset for sales operations
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we reach the users kioskownercaps
    /// * `kiosk` - defines the user's kiosk
    /// * `asset_id` - defines the assets ID
    public fun list(
        share: &mut ListedTypes,
        kiosk: &mut Kiosk,
        asset_id: ID,
        price: u64,
        ctx: &mut TxContext
        ) {
            // check the kiosk owner
            assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            // set the kiosk cap 
            let kiosk_cap = table::borrow(&share.kiosk_caps, sender(ctx));
            // borrow the asset 
            let asset = kiosk::borrow<Asset>(kiosk, kiosk_cap, asset_id);
            assert!(assets::is_approved(asset), ERROR_NOT_APPROVED);
            assert!(!assets::is_renting(asset), ERROR_ASSET_IN_RENTING);
            kiosk::list<Asset>(
                kiosk,
                kiosk_cap,
                asset_id,
                price,
            );     
    }
    /// Users can purchase any asset from the marketplace
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we reach the users kioskownercaps
    /// * `kiosk1` - defines the asset's owner kiosk
    /// * `kiosk2` - defines the buyer kiosk
    /// * `notary` - defines notary_fee storage
    /// * `policy` - defines transferpolicy for purchase process.
    /// * `payment` - the amount of asset price 
    /// * `fee` - the notary fee for every process
    public fun purchase(
        kiosk1: &mut Kiosk,
        kiosk2: &mut Kiosk,
        share: &mut ListedTypes,
        notary: &mut NotaryFee,
        policy: &TransferPolicy<Asset>,
        asset_id: ID,
        payment: Coin<SUI>,
        fee: Coin<LIRA>,
        ctx: &mut TxContext
        ) {
            // purchase the asset from kiosk
            let (item, request) = kiosk::purchase(
                kiosk1,
                asset_id,
                payment
                );
            rr::pay<Asset>(policy, &mut request, notary, fee, ctx);
            // confirm the request. Destroye the hot potato
            policy::confirm_request(policy, request);
            // be sure that sender is the owner of kiosk
            assert!(kiosk::owner(kiosk2) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
            // place the asset into the kiosk
            let kiosk_cap = table::borrow(&share.kiosk_caps, sender(ctx));
            kiosk::place(kiosk2, kiosk_cap, item);
    }
        
    /// Users can withdraw profits from own kiosk
    /// 
    /// # Arguments
    /// 
    /// * `ListedTypes` - the shareobject that we reach the users kioskownercaps
    /// * `kiosk` - defines the user's kiosk
    public fun withdraw_profits(
        kiosk: &mut Kiosk,
        shared: &ListedTypes,
        amount: Option<u64>,
        ctx: &mut TxContext
    ) : Coin<SUI> {
        // check the owner of kiosk
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // set the kiosk_cap
        let kiosk_cap = table::borrow(&shared.kiosk_caps, sender(ctx));
        // take profits from kiosk
        let profits = kiosk::withdraw(kiosk, kiosk_cap, amount, ctx);
        profits
    }

    // =================== Helper Functions ===================
    
    // return the publisher
    fun get_publisher(shared: &AssetsTypePublisher) : &Publisher {
        &shared.publisher
     }
    public(friend) fun get_cap(shared: &ListedTypes, user: address) : &KioskOwnerCap {
        let kiosk_cap = table::borrow(&shared.kiosk_caps, user);
        kiosk_cap
    }
    public(friend) fun get_witness() : NotaryKioskExtWitness {
        let witness = NotaryKioskExtWitness {};
        witness
    }
    public fun test_get_bag(kiosk: &Kiosk) :&Bag {
        let witness = get_witness();
        let bag_ = ke::storage<NotaryKioskExtWitness>(witness, kiosk);
        bag_
    }
    public fun test_get_coin_name(kiosk: &Kiosk, index: u64) : String {
        let witness = get_witness();
        let bag_ = ke::storage<NotaryKioskExtWitness>(witness, kiosk);
        let coin_names = string::utf8(b"coins");
        let coin_vector = bag::borrow<String, vector<String>>(bag_, coin_names);
        let name = vector::borrow(coin_vector, index);
        *name
    }
    public fun test_get_coin_amount<T>(kiosk: &Kiosk, coin: String) : u64 {
        let witness = get_witness();
        let bag_ = ke::storage<NotaryKioskExtWitness>(witness, kiosk);
        let coin = bag::borrow<String, Balance<T>>(bag_, coin);
        let amount = balance::value(coin);
        amount 
    }

    // =================== Test Only ===================
    #[test_only]
    // call the init function
    public fun test_init(ctx: &mut TxContext) {
        init(ASSETS_TYPE {}, ctx);
    }
    #[test_only]
    // call the init function
    public fun get_kiosk_cap(share: &ListedTypes, ctx: &mut TxContext) : &KioskOwnerCap  {
       let cap = table::borrow(&share.kiosk_caps, sender(ctx));
       cap   
    }

}
