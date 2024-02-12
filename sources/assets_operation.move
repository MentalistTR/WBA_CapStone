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
    use std::string::{Self, String};
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

    use notary::assets::{Self, Asset};

  
    // =================== Errors ===================
    // asset can not be approve again
    //const ERROR_ASSET_ALREADY_APPROVED: u64 = 1;
    // User price is not equal to asset price 
   // const ERROR_INVALID_PRICE: u64 = 2;

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
        assets: VecMap<address, Sales>,
    }
    /// Defines the share object for keep ListedAssetss to or sales
    /// 
    /// # Arguments
    /// 
    /// * `house, shop, car, land` - Users must add the assets to linkedtable for approve by admin  
    /// * `admin_fee` -  Defines the procol fee revenue
    struct ListedAssets<T: key + store> has key, store {
        id: UID,
        assets: LinkedTable<ID, Asset<T>>,
        admin_fee: Balance<LIRA_STABLE_COIN>,
    }
    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }
    // /// # Arguments
    // /// 
    // /// * `seller, buyer ` - are the addresses 
    // /// * `itemt` -  Defines type of structure
    // /// * `time` -  Defines the current time at the sales transaction.  
    struct Sales has copy, drop, store {
        seller: address,
        buyer: address,
        item: String,
        time: u64,
    }
    /// Create an account for each user
    /// # Arguments
    /// 
    /// * `debt` - Defines the user debt to protocol  
    /// * `balance` -  Defines the user balance in this protocol 
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
                assets: vec_map::empty(),
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
     /// Admin must create one share object for users to set theirs RWA for approve. 
    public fun new_listed_assets<T: key + store>(_: &AdminCap, ctx: &mut TxContext) {
            transfer::share_object(
            ListedAssets {
                id: object::new(ctx),
                assets: lt::new<ID, Asset<T>>(ctx),
                admin_fee: balance::zero(),
            }
        );
    }
     /// Users can create a asset. 
     /// # Arguments
     /// 
     /// * `location, area, year ` -  are the property of house  
     /// * `price` - Defines the house price.
    public fun create_asset<T: key + store>( 
        listed_asset: &mut ListedAssets<T>,
        account: &mut Account, 
        type: T,
        price: u64,
        ctx :&mut TxContext,
    ) : Asset<T> {
        // calculate the notary fee
        let notary_fee = balance::split(&mut account.balance, FEE / 1000);
        // transfer the notary_fee to notary balance 
        balance::join(&mut listed_asset.admin_fee, notary_fee);
        let asset = assets::create_house(type, price, ctx);
        asset
    }
    // users can deposit lira_stable_coin to theirs account balance 
    public fun deposit(account: &mut Account , coin: Coin<LIRA_STABLE_COIN>) {
        balance::join(&mut account.balance, coin::into_balance(coin));
    }
   
    //  /// Users have to add theirs assets into the Linked_table for approve by admin . 
    //  /// # Arguments
    //  /// 
    //  /// * `asset` -  share object for keep assets to approve  
    //  /// * `item` -   Defines the type 
    // public fun add_house_table(
    //     asset: &mut ListedAssets,
    //     item: House,
    // ) {
    //     // check that ListedAssets approved by admin
    //     assert!(return_house_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
    //     // check that if user doesnt has any table add it.
    //     let object_id = return_house_id(&item); 
    //     // add the object to the objecttable
    //     lt::push_back(&mut asset.house, object_id, item);
    // }

    //  /// Users have to add theirs assets into the Linked_table for approve by admin . 
    //  /// # Arguments
    //  /// 
    //  /// * `asset` -  share object for keep assets to approve  
    //  /// * `item` -   Defines the type 
    // public fun add_car_table(
    //     asset: &mut ListedAssets,
    //     item: Car,
    // ) {
    //     // check that ListedAssets approved by admin
    //     assert!(return_car_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
    //     // check that if user doesnt has any table add it.
    //     let object_id = return_car_id(&item); 
    //     // add the object to the objecttable
    //     lt::push_back(&mut asset.car, object_id, item);
    // }
    //  /// Users have to add theirs assets into the Linked_table for approve by admin . 
    //  /// # Arguments
    //  /// 
    //  /// * `asset` -  share object for keep assets to approve  
    //  /// * `item` -   Defines the type 
    //   public fun add_land_table(
    //     asset: &mut ListedAssets,
    //     item: Land,
    // ) {
    //     // check that ListedAssets approved by admin
    //     assert!(return_land_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
    //     // check that if user doesnt has any table add it.
    //     let object_id = return_land_id(&item); 
    //     // add the object to the objecttable
    //     lt::push_back(&mut asset.land, object_id, item);
    // }
    //  /// Users have to add theirs assets into the Linked_table for approve by admin . 
    //  /// # Arguments
    //  /// 
    //  /// * `asset` -  share object for keep assets to approve  
    //  /// * `item` -   Defines the type 
    //  public fun add_shop_table(
    //     asset: &mut ListedAssets,
    //     item: Shop,
    // ) {
    //     // check that ListedAssets approved by admin
    //     assert!(return_shop_bool(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
    //     // check that if user doesnt has any table add it.
    //     let object_id = return_shop_id(&item); 
    //     // add the object to the objecttable
    //     lt::push_back(&mut asset.shop, object_id, item);
    // }

    //  /// Only owner of this contract can approve assets . 
    //  /// # Arguments
    //  /// 
    //  /// * `AdminCap` -Defines the admin access object 
    //  /// * `asset` -  share object for keep assets to approve  
    //  /// * `recipient` - is the address of owner of objects  
    public fun approve_house<T: key + store>(_: &AdminCap, asset: &Asset<T>, id: ID, approve: bool) {
      
        
       
   
        }
    
    // //  /// Only owner of this contract can approve assets . 
    // //  /// # Arguments
    // //  /// 
    // //  /// * `AdminCap` -Defines the admin access object 
    // //  /// * `asset` -  share object for keep assets to approve  
    // //  /// * `recipient` - is the address of owner of objects   
    // public fun approve_car(_: &AdminCap, asset: &mut ListedAssets, id: ID, approve: bool) {
    //     // remove the asset from table 
    //     let asset = lt::remove(&mut asset.car, id);
    //     // check the asset is not approved
    //     if(approve == true) {
    //         // set the bool to approve variable 
    //         let new_asset = car_bool(asset);
    //         // define recipient 
    //         let recipient = return_car_owner(&new_asset);
    //         // transfer the object 
    //         assets::transfer_car(new_asset, recipient);
    //     } else {
    //         // if admin is not approve send the object to owner 
    //         let recipient = return_car_owner(&asset);
    //         assets::transfer_car(asset, recipient);  
    //     }
    //     }
    // //  /// Only owner of this contract can approve assets . 
    // //  /// # Arguments
    // //  /// 
    // //  /// * `AdminCap` -Defines the admin access object 
    // //  /// * `asset` -  share object for keep assets to approve  
    // //  /// * `recipient` - is the address of owner of objects  
    // public fun approve_land(_: &AdminCap, asset: &mut ListedAssets, id: ID, approve: bool) {
    //     // remove the asset from table 
    //     let asset = lt::remove(&mut asset.land, id);
    //     if(approve == true) {
    //         // set the bool to approve variable 
    //         let new_asset = land_bool(asset);
    //         // define recipient 
    //         let recipient = return_land_owner(&new_asset);
    //         // transfer the object 
    //         assets::transfer_land(new_asset, recipient);
    //     } else {
    //         // if admin is not approve send the object to owner 
    //         let recipient = return_land_owner(&asset);
    //         assets::transfer_land(asset, recipient);  
    //     }
    //     }
    // //  /// Only owner of this contract can approve assets . 
    // //  /// # Arguments
    // //  /// 
    // //  /// * `AdminCap` -Defines the admin access object 
    // //  /// * `asset` -  share object for keep assets to approve  
    // //  /// * `recipient` - is the address of owner of objects   
    // public fun approve_shop(_: &AdminCap, asset: &mut ListedAssets, id: ID, approve: bool) {
    //     // remove the asset from table 
    //     let asset = lt::remove(&mut asset.shop, id);
    //     if(approve == true) {
    //         // set the bool to approve variable 
    //         let new_asset = shop_bool(asset);
    //         // define recipient 
    //         let recipient = return_shop_owner(&new_asset);
    //         // transfer the object 
    //         assets::transfer_shop(new_asset, recipient);
    //     } else {
    //         // if admin is not approve send the object to owner 
    //         let recipient = return_shop_owner(&asset);
    //         assets::transfer_shop(asset, recipient);  
    //     }
    //     }
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
    // #[test_only]
    // public fun get_house_table(asset: &ListedAssets, id: u64, ctx: &mut TxContext) : &House {
    //     let user_table = lt::borrow(&asset.house, tx_context::sender(ctx));
    //     let house = lt::borrow(user_table, id);
    //     house
    // }
    //#[test_only]
    // get id for local test 
    // public fun test_get_house_id(asset: &ListedAssets, number: u64) : ID {
    //     let id = vector::borrow(&asset.house_id, number);
    //     *id
    // }

}

