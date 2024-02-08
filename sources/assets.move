module notary::assets {
    use std::string::{Self,String};
    use sui::object::{Self,UID,ID};
    
    use notary::lira_stable_coin::{LIRA_STABLE_COIN};

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
 





 
}
