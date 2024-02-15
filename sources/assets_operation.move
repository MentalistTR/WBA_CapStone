/// ASSETS_OPERATION module is responsible for managing ListedAssetss and their operations
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
    use std::type_name::{Self, TypeName};
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::linked_table::{Self as lt, LinkedTable};
    use sui::object_table::{Self as ot};
    use sui::package::{Self, Publisher};
    use sui::transfer_policy::{Self as tp, TransferPolicy};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::vec_set::{Self, VecSet};

    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    use notary::assets::{Self, Asset};

  
    // =================== Errors ===================

    // =================== Constants ===================

    // Fee is  the protocol receives whenever a sales transaction occurs
    // Admin can change this ratio.
    const FEE: u128 = 5;

    // =================== Structs ===================

    struct Notary<T: key + store> has key {
        id: UID,
        asset_owner: ID,
        assets: T,
        rules: VecSet<TypeName>
    }

    struct NotaryRequest {
        notary_id: ID,
        rules: VecSet<TypeName>,
        approved: vector<TypeName>,
    }

    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
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
        // transfer AdminCap object to owner 
        transfer::transfer(AdminCap 
        { id: object::new(ctx),}, tx_context::sender(ctx) );
    }

    // =================== Functions ===================
    public fun new() {
        // create share object Notary 
        
        // this function might be friend, Consider access control 
    }

    public fun request<T: store + key>(notary: &Notary<T>) : NotaryRequest {
        NotaryRequest{
            notary_id: object::id(notary),
            rules: notary.rules,
            approved: vector::empty()
        }
    }

    public fun approve() {
        // take a witness updates the request 

    }

    public fun verify() {
        // take the hot potato 
        // checks that all rules approved 
    }

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

    // === Test Functions ===
    #[test_only]
    // get init function 
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }


}
