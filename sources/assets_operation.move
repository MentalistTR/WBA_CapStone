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
    use sui::coin::{Self, Coin};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};
    use notary::assets::{
        House, Car, Land, Shop, 
        Sales, return_house, return_shop, return_land, return_car, house_bool,
        car_bool, land_bool, shop_bool,
        return_house_bool, return_car_bool, return_land_bool, return_shop_bool
        };
  

    // =================== Errors ===================
    const ERROR_ALREADY_APPROVED: u64 = 1;
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

     /// Users has to create an account. 
     /// # Arguments
     /// 
     /// * `debt` -  Defines the user debt 
     /// * `balance` - Defines the user balance
    public fun new_account(ctx: &mut TxContext): Account {
        Account {
          id: object::new(ctx),
          debt: 0,
          balance: balance::zero()
        }
    }
    
     /// Users can create a house . 
     /// # Arguments
     /// 
     /// * `location, area, year ` -  are the property of house  
     /// * `price` - Defines the house price.
    public fun create_house( 
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,
        ) {
        // create an house
        let house = return_house(location, area, year, price, ctx);
        // calculate the notary fee
        let notary_fee = balance::split(&mut account.balance, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(house, tx_context::sender(ctx));
    }
     /// Users can create shop . 
     /// # Arguments
     /// 
     /// * `location, area, year ` -  are the property of shop 
     /// * `price` - Defines the shop price.
     public fun create_shop( 
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        year: u64,
        price: u64,
        ctx :&mut TxContext,

     ) {
        // create an Shop
        let shop = return_shop(location, area, year, price, ctx);
        // calculate the notary fee
        let notary_fee = balance::split(&mut account.balance, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(shop, tx_context::sender(ctx));

    }
     /// Users can create a land . 
     /// # Arguments
     /// 
     /// * `location, area ` -  are the property of land  
     /// * `price` - Defines the land price.
     public fun create_land(
        asset: &mut Asset,
        account: &mut Account, 
        location: String,
        area: u64,
        price: u64,
        ctx :&mut TxContext,
     ) {
        // create an Land
    
        let land = return_land(location, area, price, ctx);
     
        // calculate the notary fee
        let notary_fee = balance::split(&mut account.balance, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(land, tx_context::sender(ctx));

    }
     /// Users can create a house . 
     /// # Arguments
     /// 
     /// * `model, year, color, distance ` -  are the property of car   
     /// * `price` - Defines the car price.
     public fun create_car(
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
        let car = return_car(model, year, color, distance, price, ctx);
        // calculate the notary fee
        let notary_fee = balance::split(&mut account.balance, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut asset.admin_fee, notary_fee);
        // transfer the object to sender
        transfer::public_transfer(car, tx_context::sender(ctx));
    }
    // users can deposit lira_stable_coin to theirs account balance 
    public fun deposit(account: &mut Account , coin: Coin<LIRA_STABLE_COIN>) {
        balance::join(&mut account.balance, coin::into_balance(coin));
    }
    // only admin can approve object approve 
    public fun approve_house(_: &AdminCap, self: &mut House) {
        assert!(return_house_bool(self) == false, ERROR_ALREADY_APPROVED);
        house_bool(self);
    }
    // only admin can approve object approve 
    public fun approve_car(_: &AdminCap, self: &mut Car) {
        assert!(return_car_bool(self) == false, ERROR_ALREADY_APPROVED);
        car_bool(self);
    }
    // only admin can approve object approve 
    public fun approve_land(_: &AdminCap, self: &mut Land) {
        assert!(return_land_bool(self) == false, ERROR_ALREADY_APPROVED);
        land_bool(self);
    }
    // only admin can approve object approve 
    public fun approve_shop(_: &AdminCap, self: &mut Shop) {
        assert!(return_shop_bool(self) == false, ERROR_ALREADY_APPROVED);
        shop_bool(self);
    }

    public fun add_table() {

    }

    public fun remove_table() {
        
    }

    public fun buy() {

    }

    public fun burn() {

    }

    // === Test Functions ===
    #[test_only]
    // get user Account balance 
    public fun user_account_balance(account: &Account): u64 {
        balance::value(&account.balance)
    }
    #[test_only]
    // get init function 
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
}

