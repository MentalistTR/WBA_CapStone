module notary::assets_operation {
    use std::string::{Self,String};
    use std::vector;
    use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,UID,ID};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui::table_vec::{Self, TableVec};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};
  
   // =================== Friends ===================

    // =================== Errors ===================

    // =================== Constants ===================

    const FEE: u64 = 5;

    // =================== Structs ===================

    /// Defines the share object for keep transactions(approve) 
    /// 
    /// # Arguments
    /// 
    /// There are 4 structures event that notary should keep events. 
    struct Data has key, store {
        id: UID,
        house: VecMap<address, Sales>,
        shop: VecMap<address, Sales>,
        car: VecMap<address, Sales>,
        land: VecMap<address, Sales>,
    }
    /// Defines the share object for keep assets to rent or sales
    /// 
    /// # Arguments
    /// 
    /// Users can keep store assets in ObjectTable
    /// notary fee will be keep in this object
    struct Asset has key, store {
        id: UID,
        house: Table<address,TableVec<House>>,
        shop: Table<address,TableVec<Shop>>,
        car: Table<address,TableVec<Car>>,
        land: Table<address,TableVec<Land>>,
        admin_fee: Balance<LIRA_STABLE_COIN>,
    }
    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }
    // Create an account for each user 
    struct Account has key, store {
        id: UID,
        debt: u64,
        balance: Balance<LIRA_STABLE_COIN>
    }

    // object that people can sell, buy or rent 
    struct House has key, store {
        id: UID,
        inner: ID,
        owner: address,
        location: String,
        area_meter: u64,
        year: u64,
        price: u64,
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
 
    // object that event for keep in Data Share object 
    struct Sales has copy, drop, store {
        seller: address,
        buyer: address,
        item: String,
        time: u64,
    }  

    // =================== Initializer ===================

    fun init(ctx: &mut TxContext) {
        // create and transfer Data share object
        transfer::share_object(
            Data {
                id: object::new(ctx),
                house: vec_map::empty(),
                shop: vec_map::empty(),
                car:  vec_map::empty(),
                land: vec_map::empty()
            }
        );
        //create and transfer Asset share object
        transfer::share_object(
            Asset {
                id: object::new(ctx),
                house:table::new(ctx),
                shop: table::new(ctx),
                car: table::new(ctx),
                land: table::new(ctx),
                admin_fee: balance::zero()
            }
        );
       // transfer AdminCap object to owner 
        transfer::transfer(AdminCap 
        { id: object::new(ctx),}, tx_context::sender(ctx) );
    }

    // =================== Functions ===================

    public fun create_House(
        house: &House, 
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,
        ) {
        // create an house
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
            approve: false
        };
        // calculate the notary fee
        let notary_fee = balance::split(&mut asset.admin_fee, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(house, tx_context::sender(ctx));
    }

     public fun create_shop(
        house: &Shop, 
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,

     ) {
        // create an Shop
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
            approve: false
        };
        // calculate the notary fee
        let notary_fee = balance::split(&mut asset.admin_fee, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(shop, tx_context::sender(ctx));

    }

     public fun create_land(
        land: &Land, 
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        price: u64,
        ctx :&mut TxContext,
     ) {
        // create an Land
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let land = Land {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            location: location,
            area_meter: area,
            price: price,
            approve: false
        };
        // calculate the notary fee
        let notary_fee = balance::split(&mut asset.admin_fee, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(land, tx_context::sender(ctx));

    }

     public fun create_car(
        house: &Land, 
        asset: &mut Asset,
        account: &mut Account, 
        model: String,
        year: u64,
        color: String,
        distance: u64,
        price: u64,
        ctx :&mut TxContext,
     ) {
        // create an car
        let id = object::new(ctx);
        let inner = object::uid_to_inner(&id);
        let car = Car {
            id:id,
            inner: inner,
            owner: tx_context::sender(ctx),
            model: model,
            year: year,
            color:color,
            distance: distance,
            price: price,
            approve: false
        };
        // calculate the notary fee
        let notary_fee = balance::split(&mut asset.admin_fee, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(car, tx_context::sender(ctx));
    }

    public fun approve() {

    }

    public fun add_table() {

    }

    public fun remove_table() {
        
    }

    public fun buy() {

    }

    public fun burn() {

    }

}
