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
    use sui::linked_table::{Self as lt, LinkedTable};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};
    use notary::assets::{
        Self, House, Car, Land, Shop, 
        Sales, return_house, return_shop, return_land, return_car, house_bool,
        car_bool, land_bool, shop_bool, return_house_id, return_car_id, return_land_id,
        return_shop_id, return_house_bool, return_car_bool, return_land_bool, return_shop_bool,
        return_house_owner, return_car_owner, return_land_owner, return_shop_owner, return_house_price
        };
  
    // =================== Errors ===================
    // asset can not be approve again
    const ERROR_ASSET_ALREADY_APPROVED: u64 = 1;
    // User price is not equal to asset price 
    const ERROR_INVALID_PRICE: u64 = 2;
    // admin can not approve empty table. There must be at least 1 object to approve. 
    const ERROR_EMPTY_TABLE: u64 = 3;
    // =================== Constants ===================

    // Fee is  the protocol receives whenever a sales transaction occurs
    // Admin can change this ratio.
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
        house: LinkedTable<address, LinkedTable<u64, House>>,
        shop: LinkedTable<address, LinkedTable<u64, Shop>>,
        car: LinkedTable<address, LinkedTable<u64, Car>>,
        land: LinkedTable<address, LinkedTable<u64, Land>>,
        admin_fee: Balance<LIRA_STABLE_COIN>,
        house_id: vector<ID> // FIXME: DELETE
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
                house:lt::new(ctx),
                shop: lt::new(ctx),
                car: lt::new(ctx),
                land: lt::new(ctx),
                admin_fee: balance::zero(),
                house_id: vector::empty()
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
   
     /// Users have to add theirs assets into the Linked_table for approve by admin . 
     /// # Arguments
     /// 
     /// * `asset` -  share object for keep assets to approve  
     /// * `item` -   Defines the type 
    public fun add_house_table(
        asset: &mut ListedAssets,
        item: House,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_house_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
        // check that if user doesnt has any table add it. 
        if (!lt::contains(&mut asset.house, tx_context::sender(ctx))) {
            let user_table = lt::new<u64, House>(ctx);
                 lt::push_back(&mut asset.house, tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = lt::borrow_mut(
            &mut asset.house, tx_context::sender(ctx));
        let table_length = lt::length(user_object_table);
        // add the object to the objecttable
        lt::push_back(user_object_table, table_length + 1, item);
    }

     /// Users have to add theirs assets into the Linked_table for approve by admin . 
     /// # Arguments
     /// 
     /// * `asset` -  share object for keep assets to approve  
     /// * `item` -   Defines the type 
    public fun add_car_table(
        asset: &mut ListedAssets,
        item: Car,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_car_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
        // check that if user doesnt has any table add it. 
        if (!lt::contains(&mut asset.car, tx_context::sender(ctx))) {
            let user_table = lt::new<u64, Car>(ctx);
                 lt::push_back(&mut asset.car, tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = lt::borrow_mut(
            &mut asset.car, tx_context::sender(ctx));
        let table_length = lt::length(user_object_table);
        // add the object to the objecttable
        lt::push_back(user_object_table, table_length + 1, item);
    }
     /// Users have to add theirs assets into the Linked_table for approve by admin . 
     /// # Arguments
     /// 
     /// * `asset` -  share object for keep assets to approve  
     /// * `item` -   Defines the type 
    public fun add_land_table(
        asset: &mut ListedAssets,
        item: Land,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_land_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
        // check that if user doesnt has any table add it. 
        if (!lt::contains(&mut asset.land, tx_context::sender(ctx))) {
            let user_table = lt::new<u64, Land>(ctx);
                 lt::push_back(&mut asset.land, tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = lt::borrow_mut(
            &mut asset.land, tx_context::sender(ctx));
        let table_length = lt::length(user_object_table);
        // add the object to the objecttable
        lt::push_back(user_object_table, table_length + 1, item);
    }
     /// Users have to add theirs assets into the Linked_table for approve by admin . 
     /// # Arguments
     /// 
     /// * `asset` -  share object for keep assets to approve  
     /// * `item` -   Defines the type 
    public fun add_shop_table(
        asset: &mut ListedAssets,
        item: Shop,
        ctx: &mut TxContext
    ) {
        // check that ListedAssets approved by admin
        assert!(return_shop_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
        // check that if user doesnt has any table add it. 
        if (!lt::contains(&mut asset.shop, tx_context::sender(ctx))) {
            let user_table = lt::new<u64, Shop>(ctx);
                 lt::push_back(&mut asset.shop, tx_context::sender(ctx), user_table);
                 }; 
        let user_object_table = lt::borrow_mut(
            &mut asset.shop, tx_context::sender(ctx));
        let table_length = lt::length(user_object_table);
        // add the object to the objecttable
        lt::push_back(user_object_table, table_length + 1, item);
    }

     /// Only owner of this contract can approve assets . 
     /// # Arguments
     /// 
     /// * `AdminCap` -Defines the admin access object 
     /// * `asset` -  share object for keep assets to approve  
     /// * `recipient` - is the address of owner of objects  
    public fun approve_house(_: &AdminCap, asset: &mut ListedAssets, recipient: address) {
        // take the sender linkedTable
        let sender_table = lt::borrow_mut(&mut asset.house, recipient);
        // return the sender Table length
        let table_length = lt::length(sender_table);
        assert!(table_length >=1, ERROR_EMPTY_TABLE);
        // loop until the table empty
        while(table_length > 0) {
            // remove the item from table
            let item = lt::remove(sender_table, table_length);
            // change the approve boolean
            let new_item = house_bool( item);
            // transfer the item to sender
            assets::transfer_house(new_item, recipient);
            // decrease the length 1
            table_length = table_length - 1;
        } 
    }
     /// Only owner of this contract can approve assets . 
     /// # Arguments
     /// 
     /// * `AdminCap` -Defines the admin access object 
     /// * `asset` -  share object for keep assets to approve  
     /// * `recipient` - is the address of owner of objects   
    public fun approve_car(_: &AdminCap, asset: &mut ListedAssets, recipient: address) {
        // take the sender linkedTable
        let sender_table = lt::borrow_mut(&mut asset.car, recipient);
        // return the sender Table length
        let table_length = lt::length(sender_table);
        assert!(table_length >=1, ERROR_EMPTY_TABLE);
        // loop until the table empty
        while(table_length > 0) {
            // remove the item from table
            let item = lt::remove(sender_table, table_length);
            // change the approve boolean
            let new_item = car_bool( item);
            // transfer the item to sender
            assets::transfer_car(new_item, recipient);
            // decrease the length 1
            table_length = table_length - 1;
        } 
    }
     /// Only owner of this contract can approve assets . 
     /// # Arguments
     /// 
     /// * `AdminCap` -Defines the admin access object 
     /// * `asset` -  share object for keep assets to approve  
     /// * `recipient` - is the address of owner of objects  
    public fun approve_land(_: &AdminCap, asset: &mut ListedAssets, recipient: address) {
        // take the sender linkedTable
        let sender_table = lt::borrow_mut(&mut asset.land, recipient);
        // return the sender Table length
        let table_length = lt::length(sender_table);
        assert!(table_length >=1, ERROR_EMPTY_TABLE);
        // loop until the table empty
        while(table_length > 0) {
            // remove the item from table
            let item = lt::remove(sender_table, table_length);
            // change the approve boolean
            let new_item = land_bool( item);
            // transfer the item to sender
            assets::transfer_land(new_item, recipient);
            // decrease the length 1
            table_length = table_length - 1;
        } 
    }
     /// Only owner of this contract can approve assets . 
     /// # Arguments
     /// 
     /// * `AdminCap` -Defines the admin access object 
     /// * `asset` -  share object for keep assets to approve  
     /// * `recipient` - is the address of owner of objects   
     public fun approve_shop(_: &AdminCap, asset: &mut ListedAssets, recipient: address) {
        // take the sender linkedTable
        let sender_table = lt::borrow_mut(&mut asset.shop, recipient);
        // return the sender Table length
        let table_length = lt::length(sender_table);
        assert!(table_length >=1, ERROR_EMPTY_TABLE);
        // loop until the table empty
        while(table_length > 0) {
            // remove the item from table
            let item = lt::remove(sender_table, table_length);
            // change the approve boolean
            let new_item = shop_bool( item);
            // transfer the item to sender
            assets::transfer_shop(new_item, recipient);
            // decrease the length 1
            table_length = table_length - 1;
        } 
    }
   

    // public fun buy_house(
    //     assets: &mut ListedAssets,
    //     account: &mut Account,
    //     asset: ID, 
    //     asset_owner: address,
    //     amount: u64, 
    //     ctx: &mut TxContext
    // ) { 
    //     // get seller table
    //     let user_table = ot::borrow_mut(&mut assets.house, asset_owner);
    //     // get the house
    //     let user_house = ot::remove( user_table, asset);
    //     // check the price 
    //     assert!(return_house_price(&user_house) == amount, ERROR_INVALID_PRICE); 
    //     // get balance from user account object 
    //     let price = balance::split(&mut account.balance, amount);
    //     // convert the balance to coin for transfer 
    //     let coin_price = coin::from_balance(price, ctx);
    //     // transfer the coin to owner 
    //     transfer::public_transfer(coin_price, asset_owner);
    //     // change the asset's owner 
    //     let new_asset =  assets::change_house_owner(user_house, tx_context::sender(ctx));
    //     //transfer the new object 
    //     assets::transfer_house(new_asset, tx_context::sender(ctx));
    // }

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
    // get house object from table 
    #[test_only]
    public fun get_house_table(asset: &ListedAssets, id: u64, ctx: &mut TxContext) : &House {
        let user_table = lt::borrow(&asset.house, tx_context::sender(ctx));
        let house = lt::borrow(user_table, id);
        house
    }
    #[test_only] // FIXME: DELETE 
    // get house ID 
    public fun get_house_id(asset: &ListedAssets, number: u64) : ID {
        let id = vector::borrow(&asset.house_id, number);
        *id
    }

}
