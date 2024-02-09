module notary::assets {
    use std::string::{Self,String};

    use sui::object::{Self,UID,ID};
    use sui::tx_context::{Self,TxContext};


    friend notary::assets_operation;

    // object that people can sell, buy or rent 
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
    // object that people can sell, buy or rent 
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
    // object that people can sell, buy or rent 
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
    // object that people can sell, buy or rent 
    struct Land has key, store {
        id: UID,
        inner: ID,
        owner: address,
        location: String,
        area_meter: u64,
        price: u64,
        approve: bool
    }
 
    // object that event for keep in NotaryData Share object 
    struct Sales has copy, drop, store {
        seller: address,
        buyer: address,
        item: String,
        time: u64,
    }

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
    public(friend) fun house_bool(self: &mut House)  {
         self.approve = true;
    }
    // helper function that check house.approve equal to false
    public fun return_house_bool(self: &House) : bool {
        self.approve
    }

      // change the house object approve bool to true 
    public(friend) fun car_bool(self: &mut Car)  {
         self.approve = true;
    }
    // helper function that check house.approve equal to false
    public fun return_car_bool(self: &Car) : bool {
        self.approve
    }

      // change the house object approve bool to true 
    public(friend) fun land_bool(self: &mut Land)  {
         self.approve = true;
    }
    // helper function that check house.approve equal to false
    public fun return_land_bool(self: &Land) : bool {
        self.approve
    }

      // change the house object approve bool to true 
    public(friend) fun shop_bool(self: &mut Shop)  {
         self.approve = true;
    }
    // helper function that check house.approve equal to false
    public fun return_shop_bool(self: &Shop) : bool {
        self.approve
    }
    // return House object ID for add table 
    public fun return_house_id(self:&House) : ID {
        self.inner
    }
    // return Car object ID for add table 
    public fun return_car_id(self:&Car) : ID {
        self.inner
    }
    // return Land object ID for add table 
    public fun return_land_id(self:&Land) : ID {
        self.inner
    }
    // return Shop object ID for add table 
    public fun return_shop_id(self:&Shop) : ID {
        self.inner
    }

   

}
