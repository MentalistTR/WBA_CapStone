module notary::assets_renting {

    use std::string::{String};
    
    use sui::tx_context::{Self, TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;

    // use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::table::{Self, Table}; 

    use notary::assets::{Self, Asset};
    use notary::assets_type::{Self as at, ListedTypes};

    // =================== Errors ===================

    const ERROR_NOT_APPROVED: u64 = 2;
    const ERROR_NOT_KIOSK_OWNER: u64 = 3;
    const ERROR_ASSET_IN_RENTING: u64 = 4;

    // =================== Structs ===================

    struct Contracts has key {
        id: UID,
        contracts: Table<address, Contract>,
        complaints: Table<address, Complaint>,
        purchase_cap: Table<ID, PurchaseCap<Asset>>
    }

    struct Contract has store, copy, drop {
        owner: address,
        leaser: address,
        item: ID,
        start: u64,
        end: u64,
    }

    struct Complaint has store, copy, drop {
        complainant: address,
        pleader: address,
        reason: String,
        decision: bool,
        active: bool
    }

    // =================== Initializer ===================

    fun init(ctx: &mut TxContext) {
        // share the Contracts
        transfer::share_object(Contracts{
            id: object::new(ctx),
            contracts: table::new(ctx),
            complaints: table::new(ctx),
            purchase_cap: table::new<ID, PurchaseCap<Asset>>(ctx), 
        });
    }

    // =================== Functions ===================

    public fun list_with_purchase_cap(
        contract: &mut Contracts,
        share: &mut ListedTypes,
        kiosk: &mut Kiosk,
        asset_id: ID,
        price: u64,
        buyer: address,
        ctx: &mut TxContext
    ) {
        // check the kiosk owner
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // set the kiosk cap 
        let kiosk_cap = at::get_cap(share, sender(ctx));
         // borrow the asset 
        let asset = kiosk::borrow<Asset>(kiosk, kiosk_cap, asset_id);
        assert!(assets::is_approved(asset), ERROR_NOT_APPROVED);
        assert!(!assets::is_renting(asset), ERROR_ASSET_IN_RENTING);
        let purch_cap = kiosk::list_with_purchase_cap<Asset>(
            kiosk,
            kiosk_cap,
            asset_id,
            price,
            ctx
        );
        // send the purchase_cap to leaser
        transfer::public_transfer(purch_cap, buyer);
    }

    public fun rent() {

    }

    public fun complain() {

    }

    public fun provision() {

    }



    
    // =================== Helper Functions ===================
    

    // =================== Test Only ===================


}