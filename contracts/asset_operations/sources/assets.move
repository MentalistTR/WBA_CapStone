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
    use sui::tx_context::{TxContext};
    use sui::vec_set::{Self, VecSet};
    use sui::vec_map::{Self, VecMap};
    use std::type_name::{TypeName};

    use std::string::{String};

    // === Friends ===

    friend notary::assets_type;
    friend notary::assets_renting;
    
  
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
        approve: bool,
        on_rent: bool,
        rules: VecSet<TypeName>,
        property: VecMap<String, String>,
    }

    struct Wrapper has key, store {
        id: UID,
        asset: Asset
    }

    public fun wrap(empty: Asset, ctx: &mut TxContext) : Wrapper {
        let rent = Wrapper {
            id: object::new(ctx),
            asset:empty
        };
        rent
    }

    public fun unwrap(w: Wrapper) : Asset {
        let Wrapper {id, asset} = w;
        object::delete(id);
        asset
    }

    // create any asset and place it to kiosk. 
    public fun create_asset(
        type: String,
        ctx :&mut TxContext,
        ) : Asset {
        
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let asset = Asset {
            id:id,
            owner:inner,
            type: type,
            on_rent: false,
            approve: false,
            rules: vec_set::empty(),
            property: vec_map::empty(),
        };
        asset
    }
    // The owner of asset can make new property 
    public(friend) fun new_property(item: &mut Asset, property_name: String, property: String) {
        vec_map::insert(&mut item.property, property_name, property);
    }
    // The owner of asset can remove property 
    public(friend) fun remove_property(item: &mut Asset, property_name: String) {
        vec_map::remove(&mut item.property, &property_name);
    }

    // helper functions 

    public(friend) fun borrow_id(asset: &Asset) : ID {
        asset.owner
    }

    public fun is_approved(asset: &Asset) : bool {
        asset.approve
    }

    public fun is_renting(asset: &Asset) : bool {
        asset.on_rent
    }

    public(friend) fun approve_asset(asset: &mut Asset)  {
        asset.approve = true;
    }
    
    public(friend) fun disapprove_asset(asset: &mut Asset) {
        asset.approve = false;
    }

    public(friend) fun disable_rent(asset: &mut Asset)  {
        asset.on_rent = false;
    }

    public(friend) fun active_rent(asset: &mut Asset)  {
        asset.on_rent = true;
    }}
