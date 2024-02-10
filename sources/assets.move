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

    /// Defines the house object that users can create
    /// 
    /// # Arguments
    /// 
    /// * `inner, owner, location, area_meter, year ,price ` - are the property of this structure
    /// * `on_rent` -  Defines the rentable
    /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct House has key, store {
        id: UID,
        inner: ID,
        owner: address,
        location: String,
        area_meter: u64,
        year: u64,
        price: u64,
        on_rent: bool,
        approve: bool
    }  
    /// Defines the house object that users can create
    /// 
    /// # Arguments
    /// 
    /// * `inner, owner, location, area_meter, year ,price ` - are the property of this structure
    /// * `on_rent` -  Defines the rentable
    /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct Shop has key, store {
        id: UID,
        inner: ID,
        owner: address,
        location: String,
        area_meter: u64,
        year: u64,
        price: u64,
        on_rent: bool,
        approve: bool
    }
    /// Defines the house object that users can create
    /// 
    /// # Arguments
    /// 
    /// * `inner, owner, location, distance, year ,price ` - are the property of this structure
    /// * `approve` -  Defines the object is the reel asset. It is approved by admin.  
    struct Car has key, store {
        id: UID,
        inner: ID,
        owner: address,
        model: String,
        year: u64,
        color: String,
        distance: u64,
        price: u64,
        approve: bool
    }
    /// Defines the house object that users can create
    /// 
    /// # Arguments
    /// 
    /// * `inner, owner, location, area_meter ,price ` - are the property of this structure
    /// * `approve` -  Defines the object is the reel asset. It is approved by admin. 
    struct Land has key, store {
        id: UID,
        inner: ID,
        owner: address,
        location: String,
        area_meter: u64,
        price: u64,
        approve: bool
    }
    /// Defines the event that protocol will be keep in the data share object whenever a sales transaction occurs
    /// 
    /// # Arguments
    /// 
    /// * `seller, buyer ` - are the addresses 
    /// * `itemt` -  Defines type of structure
    /// * `time` -  Defines the current time at the sales transaction.  
    struct Sales has copy, drop, store {
        seller: address,
        buyer: address,
        item: String,
        time: u64,
    }
    // Return a new item to asset_operation module. 
    public fun return_house(
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,
        ): House {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let house = House {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            location: location,
            area_meter: area,
            year: year,
            price: price,
            on_rent: false,
            approve: false
        };
        house
    }
    // Return a new item to asset_operation module. 
    public fun return_car(
        model: String,
        year: u64,
        color: String,
        distance: u64,
        price: u64,
        ctx :&mut TxContext,
        ): Car {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let car = Car {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            model: model,
            year: year,
            color: color,
            distance: distance,
            price: price,
            approve: false
        };
        car
    }
    // Return a new item to asset_operation module. 
    public fun return_land(
        location: String,
        area: u64,
        price: u64,
        ctx :&mut TxContext,
        ): Land {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let land = Land{
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            location: location,
            area_meter: area,
            price: price,
            approve: false
        };
        land
    }
    // Return a new item to asset_operation module. 
    public fun return_shop(
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,
        ): Shop {
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let shop = Shop {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            location: location,
            area_meter: area,
            year: year,
            price: price,
            on_rent: false,
            approve: false
        };
        shop
    }
    // change the house object approve bool to true 
    public(friend) fun house_bool(self: House) : House {
         self.approve = true;
         self
    }
    // change the car object approve bool to true 
    public(friend) fun car_bool(self: Car) : Car  {
         self.approve = true;
         self
    }
    // change the land object approve bool to true 
    public(friend) fun land_bool(self: Land) : Land  {
         self.approve = true;
         self
    }
    // change the shop object approve bool to true 
    public(friend) fun shop_bool(self: Shop) : Shop  {
         self.approve = true;
         self
    }
    // helper function that check house.approve equal to false
    public fun return_house_bool(self: &House) : bool {
        self.approve
    }
    // helper function that check house.approve equal to false
    public fun return_car_bool(self: &Car) : bool {
        self.approve
    }
    // helper function that check house.approve equal to false
    public fun return_land_bool(self: &Land) : bool {
        self.approve
    }
    // helper function that check house.approve equal to false
    public fun return_shop_bool(self: &Shop) : bool {
        self.approve
    }
    // return House object ID for add table 
    public fun return_house_id(self: &House) : ID {
        self.inner
    }
    // return Car object ID for add table 
    public fun return_car_id(self: &Car) : ID {
        self.inner
    }
    // return Land object ID for add table 
    public fun return_land_id(self: &Land) : ID {
        self.inner
    }
    // return Shop object ID for add table 
    public fun return_shop_id(self: &Shop) : ID {
        self.inner
    }
    // return House object owner
    public fun return_house_owner(self: &House): address {
        self.owner
    }
     // return Land object owner
    public fun return_land_owner(self: &Land): address {
        self.owner
    }
     // return Car object owner
    public fun return_car_owner(self: &Car): address {
        self.owner
    }
     // return Shop object owner
    public fun return_shop_owner(self: &Shop): address {
        self.owner
    }
    // return the house price 
    public fun return_house_price(self: &House): u64 {
        self.price
    }
    // transfer house object 
    public fun transfer_house(self: House, recipient: address) {
        transfer::public_transfer(self, recipient);
    }
    // transfer Car object 
    public fun transfer_car(self: Car, recipient: address) {
        transfer::public_transfer(self, recipient);
    }
    // transfer Land object 
    public fun transfer_land(self: Land, recipient: address) {
        transfer::public_transfer(self, recipient);
    }
    // transfer Shop object 
    public fun transfer_shop(self: Shop, recipient: address) {
        transfer::public_transfer(self, recipient);
    }
    // change the owner of this structure when sales transactions occurs.
    public fun change_house_owner(self: House, recipient: address) : House {
        self.owner = recipient;
        self
    }
}
