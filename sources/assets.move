module notary::assets {

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
 
    // object that event for keep in Data Share object 
    struct Sales<T> has copy, drop {
        seller: address,
        buyer: address,
        item: T,
        time: u64,
    }

}
