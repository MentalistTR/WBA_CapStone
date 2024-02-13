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
    use std::string::{String};
    use std::vector;
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,UID,ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::linked_table::{Self as lt, LinkedTable};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{Self, Asset, Accessory};

  
    // =================== Errors ===================
    // asset can not be approve again
    const ERROR_ASSET_ALREADY_APPROVED: u64 = 1;
    const ERROR_INVALID_TYPE: u64 = 2;

    // =================== Constants ===================

    // Fee is  the protocol receives whenever a sales transaction occurs
    // Admin can change this ratio.
    const FEE: u128 = 5;

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
    struct ListedAssets has key, store {
        id: UID,
        assets: LinkedTable<ID, Asset>,
        admin_fee: Balance<LIRA_STABLE_COIN>,
        types: vector<String>
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
     // users can deposit lira_stable_coin to theirs account balance 
    public fun deposit(account: &mut Account , coin: Coin<LIRA_STABLE_COIN>) {
        balance::join(&mut account.balance, coin::into_balance(coin));
    }
     /// Admin must create one share object for users to set theirs RWA for approve. 
    public fun new_listed_assets(_: &AdminCap, ctx: &mut TxContext) {
            transfer::share_object(
            ListedAssets {
                id: object::new(ctx),
                assets: lt::new<ID, Asset>(ctx),
                admin_fee: balance::zero(),
                types: vector::empty()
            }
        );
    }
    /// Users can create a asset. 
    /// # Arguments
    /// * `account ` -  is the user accout that keep debt or balance.
    /// * `type ` -  is the wrapped object. It can be house, car , plane 
    /// * `price` - Defines the asset price.
    public fun create_asset( 
        listed_asset: &mut ListedAssets,
        account: &mut Account, 
        type: String,
        price: u64,
        ctx :&mut TxContext,
    ) : Asset {
        assert!(vector::contains(&listed_asset.types, &type) == true, ERROR_INVALID_TYPE);
        // set the account total value
        let value = balance::value(&account.balance);
        // calculate the deposit amount 
        let admin_fee = value - (((value as u128) * FEE / 1000) as u64);
        // take admin fee from account balance 
        let notary_fee = balance::split(&mut account.balance, value - admin_fee);
        // transfer the notary_fee to notary balance 
        balance::join(&mut listed_asset.admin_fee, notary_fee);
        let asset = assets::create_asset(type, price, ctx);
        asset
    }
   
    /// Users have to add theirs assets into the Linked_table for approve by admin . 
    /// # Arguments
    /// 
    /// * `asset` -  share object for keep assets to approve  
    /// * `item` -   Defines the type 
    public fun add_asset_table(
        asset: &mut ListedAssets,
        item: Asset,
    ) {
        // check the asset approved or not.
        assert!(assets::return_asset_approve(&item) == false, ERROR_ASSET_ALREADY_APPROVED);
        // set the object id.
        let object_id = assets::return_asset_id(&item); 
        // add the object to the objecttable
        lt::push_back(&mut asset.assets, object_id, item);
    }

    public fun approve_asset(_: &AdminCap, listed_asset: &mut ListedAssets, id: ID, approve: bool) {
        // remove the asset from table 
        let asset = lt::remove(&mut listed_asset.assets, id);
        if(approve == true) {
            // set the bool to approve variable 
            let new_asset = assets::return_new_asset( asset);
            // define recipient 
            let recipient = assets::return_asset_owner(&new_asset);
            // transfer the object 
            assets::transfer_asset(new_asset, recipient);
        } else {
            // if admin is not approve send the object to owner 
            let recipient = assets::return_asset_owner(&asset);
            assets::transfer_asset(asset, recipient);  
        }
    }

    // Add extensions to reel world assets 

    // public fun add_accessory(asset: &mut Asset, property: String, ctx: &mut TxContext) {
    //     let wrapped_asset = assets::return_wrapped(asset);
    //     let new_accessory = assets::create_accessory(property, ctx);
    //     let accessory_id = 
        
       


          
        

    // }


    
   



    public fun burn() {

    }

    // === Test Functions ===
    #[test_only]
    // get init function 
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
    #[test_only]
    // get account balance 
    public fun get_account_balance(account: &Account) : u64 {
        balance::value(&account.balance)
    } 
    #[test_only]
    // get account debt
    public fun get_account_debt(account: &Account) : u64 {
        account.debt
    } 
    #[test_only]
    // get admin balance 
    public fun get_admin_balance(share: &ListedAssets) : u64 {
        balance::value(&share.admin_fee)
    }

}
