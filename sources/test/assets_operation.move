module notary::assets_operation {
    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self,UID,ID};
    use sui::transfer;


     // =================== Errors ===================



    /// Defines the share object for keep transactions(approve) 
    /// 
    /// # Arguments
    /// 
    /// 
    struct Data has key {
        
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
