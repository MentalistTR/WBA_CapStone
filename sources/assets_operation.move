module notary::assets_operation {
    use std::string::{Self,String};
    use std::vector;
    use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,UID,ID};
    use sui::transfer;
    use sui::table::{Self, Table};

    use notary::lira_stable_coin::{TR_LIRA};


    // =================== Errors ===================




    /// Defines the share object for keep transactions(approve) 
    /// 
    /// # Arguments
    /// 
    /// There are 4 structures event that notary should keep events. 
    struct Data<T> has key {
        id: UID,
        house: Table<address, vector<Sales<T>>>,
        shop: Table<address, vector<Sales<T>>>,
        car: Table<address, vector<Sales<T>>>,
        land: Table<address, vector<Sales<T>>>,
        //user_operations:Table<address,Table<String, String>>,
 
    }
    /// Defines the share object for keep assets to rent or sales
    /// 
    /// # Arguments
    /// 
    /// 
    struct Asset has key {

    }
    // object that people can sell, buy or rent 
    struct House has key {

    }  
    // object that people can sell, buy or rent 
    struct Shop has key {

    }
    // object that people can sell, buy or rent 
    struct Car has key {

    }
    // object that people can sell, buy or rent 
    struct Land has key {

    }
    // Only owner of this module can access it.
    struct AdminCap has key {

    }
    // object that event for keep in Data Share object 

    struct Sales<T> has copy, drop {
        seller: address,
        buyer: address,
        item: T,
        time: u64,
    }

    // =================== Initializer ===================

    fun init() {

    }

    // =================== Functions ===================

    public fun create() {

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
