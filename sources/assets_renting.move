module notary::assets_renting {

    use std::string::{String};
    
    use sui::tx_context::{Self, TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;

    // use sui::transfer_policy::{Self as policy, TransferPolicy};
    // use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
    use sui::table::{Self, Table}; 

    use notary::assets::{Self, Asset};

    // =================== Errors ===================


    // =================== Structs ===================

    struct Contracts has key {
        id: UID,
        contracts: Table<address, Contract>,
        complaints: Table<address, Complaint>
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
            complaints: table::new(ctx)
        });
    }

    // =================== Functions ===================

    public fun list_rent() {

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