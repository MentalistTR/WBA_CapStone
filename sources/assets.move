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
    use std::string::{Self,String};

    use sui::object::{Self,UID,ID};
    use sui::tx_context::{Self,TxContext};
    use sui::transfer;


    friend notary::assets_operation;

    // /// # Arguments
    // /// 
    // /// * `type ` - is the type of the asset such as house, car, plane
    // /// * `price` -    Defines the price of asset 
    // /// * `on_rent` -  Defines the rentable
    // /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct Asset<T: key + store> has key, store {
        id: UID,
        inner: ID,
        owner: address,
        type: T,
        price: u64,
        approve: bool,
        on_rent: bool
    }
    // return a asset to create
    public fun create_house<T: key + store>(
        type: T,
        price: u64,
        ctx :&mut TxContext,
        ): Asset<T> {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let house = Asset {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            type: type,
            price: price,
            on_rent: false,
            approve: false
        };
        house
    }

    // helper functions 

    public fun return_asset_approve<T: key + store>(asset: &Asset<T>) : bool {
        asset.approve
    }

    public fun return_asset_id<T: key + store>(asset: &Asset<T>) : ID {
        asset.inner
    }



}
