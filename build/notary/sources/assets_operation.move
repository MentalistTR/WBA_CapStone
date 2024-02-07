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
    use notary::assets::{House, Shop, Land, Car, Sales};


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
        // create and transfer Asset share object
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
