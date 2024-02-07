module notary::assets {
    use std::string::{Self,String};
    use sui::object::{UID};

    // object that people can sell, buy or rent 
    struct House has key, store {
        id:UID

    }  
    // object that people can sell, buy or rent 
    struct Shop has key, store {
        id:UID

    }
    // object that people can sell, buy or rent 
    struct Car has key, store {
        id:UID

    }
    // object that people can sell, buy or rent 
    struct Land has key, store {
        id:UID
    }
 
    // object that event for keep in Data Share object 
    struct Sales has copy, drop, store {
        seller: address,
        buyer: address,
        item: String,
        time: u64,
    }

}
