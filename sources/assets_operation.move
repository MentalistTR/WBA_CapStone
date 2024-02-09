/// asset_operation module is responsible for managing ListedAssetss and their operations
/// 
/// # Related Modules
/// 
/// * `Assets` - to call objects for create to system
/// * `Lira_Stable_Coin` - calls `LIRA_STABLE_COIN` to mint and burn stable coins
///
/// There are four main operations in this module:
/// 
/// 1. Creates and approve objects 
/// 2. Buy assets from seller
/// 3. Create an account for keep balance or debt
/// 4. Keep Sales events in Data share object
module notary::assets_operation {
    use std::string::{Self,String};
    use std::vector;
    use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,UID,ID};
    use sui::transfer;
    use sui::object_table::{Self as ot, ObjectTable};
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui::table_vec::{Self, TableVec};
    use sui::coin::{Self, Coin};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};
    use notary::assets::{
        House, Car, Land, Shop, 
        Sales, return_house, return_shop, return_land, return_car, house_bool,
        car_bool, land_bool, shop_bool, return_house_id, return_car_id, return_land_id,
        return_shop_id, return_house_bool, return_car_bool, return_land_bool, return_shop_bool,
        return_house_owner, return_car_owner, return_land_owner, return_shop_owner
        };
  

    // =================== Errors ===================
    const ERROR_ALREADY_APPROVED: u64 = 1;
    const ERROR_ListedAssets_NOT_APPROVED: u64 = 2;
    const ERROR_NOT_OWNER_ASSET : u64 = 3;
    // =================== Constants ===================

    const FEE: u64 = 5;

    // =================== Structs ===================

    /// Defines the share object for keep transactions(approve) 
    /// 
    /// # Arguments
    /// 
    /// There are 4 structures event that notary should keep events. 
    struct NotaryData has key, store {
        id: UID,
        house: VecMap<address, Sales>,
        shop: VecMap<address, Sales>,
        car: VecMap<address, Sales>,
        land: VecMap<address, Sales>,
    }
    /// Defines the share object for keep ListedAssetss to or sales
    /// 
    /// # Arguments
    /// 
    /// Users can keep store ListedAssetss in ObjectTable
    /// notary fee will be keep in this object
    struct ListedAssets has key, store {
        id: UID,
        house: ObjectTable<address, ObjectTable<ID, House>>,
        shop: ObjectTable<address, ObjectTable<ID, Shop>>,
        car: ObjectTable<address, ObjectTable<ID, Car>>,
        land: ObjectTable<address, ObjectTable<ID, Land>>,
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
        // create and transfer NotaryData share object
        transfer::share_object(
            NotaryData {
                id: object::new(ctx),
                house: vec_map::empty(),
                shop: vec_map::empty(),
                car:  vec_map::empty(),
                land: vec_map::empty()
            }
        );
        //create and transfer ListedAssets share object
        transfer::share_object(
            ListedAssets {
                id: object::new(ctx),
                house:ot::new(ctx),
                shop: ot::new(ctx),
                car: ot::new(ctx),
                land: ot::new(ctx),
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
        asset: &mut ListedAssets,
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
        asset: &mut ListedAssets,
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
        asset: &mut ListedAssets,
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
        asset: &mut ListedAssets,
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

     /// Users has to add ListedAssetss to table Adds to the table  . 
     /// # Arguments
     /// 
     /// * `model, year, color, distance ` -  are the property of car   
     /// * `price` - Defines the car price.
    public fun add_house_table(
        asset: &mut ListedAssets,
        item: House,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_house_bool(&item) == true, ERROR_ListedAssets_NOT_APPROVED);
        // get object ID from ListedAssets module
        let object_id = return_house_id(&item);
        // check that if user doesnt has any table add it. 
        if (!ot::contains(&mut asset.house, tx_context::sender(ctx))) {
            let user_table = ot::new(ctx);
                 ot::add(&mut asset.house,tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = ot::borrow_mut(
            &mut asset.house, tx_context::sender(ctx));
        // add the object to the objecttable
        ot::add(user_object_table, object_id, item);
    }

     /// Users has to add ListedAssetss to table Adds to the table  . 
     /// # Arguments
     /// 
     /// * `model, year, color, distance ` -  are the property of car   
     /// * `price` - Defines the car price.
    public fun add_car_table(
        asset: &mut ListedAssets,
        item: Car,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_car_bool(&item) == true, ERROR_ListedAssets_NOT_APPROVED);
        // get object ID from ListedAssets module
        let object_id = return_car_id(&item);
        // check that if user doesnt has any table add it. 
        if (!ot::contains(&mut asset.car, tx_context::sender(ctx))) {
            let user_table = ot::new(ctx);
                 ot::add(&mut asset.car,tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = ot::borrow_mut(
            &mut asset.car, tx_context::sender(ctx));
        // add the object to the objecttable
        ot::add(user_object_table, object_id, item);
    }
     /// Users has to add ListedAssetss to table Adds to the table  . 
     /// # Arguments
     /// 
     /// * `model, year, color, distance ` -  are the property of car   
     /// * `price` - Defines the car price.
    public fun add_land_table(
        asset: &mut ListedAssets,
        item: Land,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_land_bool(&item) == true, ERROR_ListedAssets_NOT_APPROVED);
        // get object ID from ListedAssets module
        let object_id = return_land_id(&item);
        // check that if user doesnt has any table add it. 
        if (!ot::contains(&mut asset.land, tx_context::sender(ctx))) {
            let user_table = ot::new(ctx);
                 ot::add(&mut asset.land,tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = ot::borrow_mut(
            &mut asset.land, tx_context::sender(ctx));
        // add the object to the objecttable
        ot::add(user_object_table, object_id, item);
    }

     /// Users has to add ListedAssetss to table Adds to the table  . 
     /// # Arguments
     /// 
     /// * `model, year, color, distance ` -  are the property of car   
     /// * `price` - Defines the car price.
    public fun add_shop_table(
        asset: &mut ListedAssets,
        item: Shop,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_shop_bool(&item) == true, ERROR_ListedAssets_NOT_APPROVED);
        // get object ID from ListedAssets module
        let object_id = return_shop_id(&item);
        // check that if user doesnt has any table add it. 
        if (!ot::contains(&mut asset.shop, tx_context::sender(ctx))) {
            let user_table = ot::new(ctx);
                 ot::add(&mut asset.shop,tx_context::sender(ctx), user_table);
                 };  
        let user_object_table = ot::borrow_mut(
            &mut asset.shop, tx_context::sender(ctx));
        // add the object to the objecttable
        ot::add(user_object_table, object_id, item);
    }

    public fun remove_house_table(
        asset: &mut ListedAssets,
        item: &House,
        ctx: &mut TxContext
    ) {
        // check that asset owner is the sender 
        assert!(return_house_owner(item) == tx_context::sender(ctx), ERROR_NOT_OWNER_ASSET);
        // take sender table from share object 
        let sender_table = ot::borrow_mut(&mut asset.house, tx_context::sender(ctx));
        // return the item ID
        let house_id = return_house_id(item);
        // remove asset from table
        let asset =  ot::remove(sender_table, house_id);
        // sent it to sender 
        transfer::public_transfer(asset, tx_context::sender(ctx)); 
    }

    public fun remove_shop_table(
        asset: &mut ListedAssets,
        item: &Shop,
        ctx: &mut TxContext
    ) {
        // check that asset owner is the sender 
        assert!(return_shop_owner(item) == tx_context::sender(ctx), ERROR_NOT_OWNER_ASSET);
        // take sender table from share object 
        let sender_table = ot::borrow_mut(&mut asset.house, tx_context::sender(ctx));
        // return the item ID
        let house_id = return_shop_id(item);
        // remove asset from table
        let asset =  ot::remove(sender_table, house_id);
        // sent it to sender 
        transfer::public_transfer(asset, tx_context::sender(ctx)); 
    }

    public fun remove_land_table(
        asset: &mut ListedAssets,
        item: &Land,
        ctx: &mut TxContext
    ) {
        // check that asset owner is the sender 
        assert!(return_land_owner(item) == tx_context::sender(ctx), ERROR_NOT_OWNER_ASSET);
        // take sender table from share object 
        let sender_table = ot::borrow_mut(&mut asset.house, tx_context::sender(ctx));
        // return the item ID
        let house_id = return_land_id(item);
        // remove asset from table
        let asset =  ot::remove(sender_table, house_id);
        // sent it to sender 
        transfer::public_transfer(asset, tx_context::sender(ctx)); 
    }

    public fun remove_car_table(
        asset: &mut ListedAssets,
        item: &Car,
        ctx: &mut TxContext
    ) {
        // check that asset owner is the sender 
        assert!(return_car_owner(item) == tx_context::sender(ctx), ERROR_NOT_OWNER_ASSET);
        // take sender table from share object 
        let sender_table = ot::borrow_mut(&mut asset.house, tx_context::sender(ctx));
        // return the item ID
        let house_id = return_car_id(item);
        // remove asset from table
        let asset =  ot::remove(sender_table, house_id);
        // sent it to sender 
        transfer::public_transfer(asset, tx_context::sender(ctx)); 
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

