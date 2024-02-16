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
    use sui::vec_set::{Self, VecSet};
    use sui::vec_map::{Self, VecMap};
    use std::type_name::{TypeName};


    use std::string::{String};
    use std::vector;



    // /// # Arguments
    // /// 
    // /// * `type ` - is the type of the asset such as house, car, plane
    // /// * `price` -    Defines the price of asset 
    // /// * `on_rent` -  Defines the rentable
    // /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct Asset has key, store {
        id: UID,
        owner: ID,
        type: String,
        price: u64,
        approve: bool,
        on_rent: bool,
        rules: VecSet<TypeName>,
        property: VecMap<String, String>,
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
            owner:inner,
            type: type,
            price: price,
            on_rent: false,
            approve: false,
            rules: vec_set::empty(),
            property: vec_map::empty(),
        };
        asset
    }


    // helper functions 

    // public fun is_approved(asset: &Asset) : bool {
    //     asset.approve
    // }

    // public(friend) fun mint_new_asset(asset: Asset) : Asset {
    //     asset.approve = true;
    //     asset
    // }

    // public(friend) fun transfer_asset(asset: Asset, owner: address) {
    //     transfer::public_transfer(asset, owner);
    // }

    // public fun get_accessory_id(accessory: &Accessory) : ID {
    //     accessory.inner
    // }

    // public fun get_accessory_property(accessory: &Accessory) : String {
    //     accessory.property
    // }
    
    // public fun get_objecttable_mut(asset: &mut Asset) : &mut ObjectTable<ID, Accessory> {
    //     &mut asset.property
    // }

    // public fun get_accessory_table(asset: &Asset, acc_id: ID) : &Accessory {
    //     let acc = ot::borrow(&asset.property, acc_id);
    //     acc
    // }

    // public fun vector_id_mut(asset: &mut Asset) : &mut vector<ID> {
    //     &mut asset.property_id
    // }

    // public fun get_accessory(asset: &Asset, id: ID): &Accessory {
    //     let acc = ot::borrow(&asset.property, id);
    //     acc
    // }

    // public fun get_accessory_vector_id(asset: &Asset) : ID {
    //    let asd =  vector::borrow(&asset.property_id, 0);
    //    *asd
    // }

    // public fun destructure_accessory(acc: Accessory) : (UID, ID, String) {
    //     let Accessory {id, inner, property} = acc;
    //     (id, inner, property)
    // }

}
