/// ListedAssetss_operation module is responsible for managing structs (Assets) and their operations
/// 
/// # Related Modules
/// 
/// * `Assets_operation` - to call structs and create the objects
///
/// There are two main operations in this module:
/// 
/// 1. Define structures
/// 2. Return structs variables
module notary::assets {

    use sui::object::{Self,UID,ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::string::{String};
    use sui::object_table::{Self as ot, ObjectTable};


    friend notary::assets_operation;

    // /// # Arguments
    // /// 
    // /// * `type ` - is the type of the asset such as house, car, plane
    // /// * `price` -    Defines the price of asset 
    // /// * `on_rent` -  Defines the rentable
    // /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct Asset has key, store {
        id: UID,
        inner: ID,
        owner: address,
        type: String,
        price: u64,
        approve: bool,
        on_rent: bool,
        property: ObjectTable<ID, Accessory>
    }
    // this struct represents the extensions of Asset
    struct Accessory has key, store {
         id: UID,
         inner: ID,
         property: String 
    }

    // return a asset to create
    public fun create_asset(
        type: String,
        price: u64,
        ctx :&mut TxContext,
        ): Asset {
        
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let asset = Asset {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            type: type,
            price: price,
            on_rent: false,
            approve: false,
            property: ot::new(ctx)
        };
        asset
    }
    public fun create_accessory(property: String, ctx: &mut TxContext) : Accessory {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let new_accessory = Accessory {
            id: id,
            inner: inner,
            property: property
        };
        new_accessory
    }

    // helper functions 

    public fun return_asset_approve(asset: &Asset) : bool {
        asset.approve
    }

    public fun return_asset_id(asset: &Asset) : ID {
        asset.inner
    }

    public(friend) fun return_new_asset(asset: Asset) : Asset {
        asset.approve = true;
        asset
    }

    public fun return_asset_owner(asset: &Asset) : address {
        asset.owner
    }

    public(friend) fun transfer_asset(asset: Asset, owner: address) {
        transfer::public_transfer(asset, owner);
    }

    public fun return_uid_to_inner(accessory: &Accessory) : ID {
        accessory.inner
    }
    
    public fun add_table_accessory(asset: &mut Asset) : &mut ObjectTable<ID, Accessory> {
        &mut asset.property
    }
    

}
