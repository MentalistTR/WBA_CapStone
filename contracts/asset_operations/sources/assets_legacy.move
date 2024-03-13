module notary::assets_legacy {
    use sui::object::{Self, UID, ID};
    use sui::table::{Self, Table};
    use sui::bag::{Self, Bag};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use sui::kiosk::{Self, Kiosk, PurchaseCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use sui::clock::{Self, Clock, timestamp_ms};

    use std::vector;
    use std::string::{Self, String};

    use notary::assets_type::{Self as at, NotaryKioskExtWitness, AdminCap, get_witness};

    // =================== Errors ===================

    const ERROR_INVALID_ARRAY_LENGTH: u64 = 0;
    const ERROR_INVALID_PERCENTAGE_SUM: u64 = 1;
    const ERROR_YOU_ARE_NOT_HEIR: u64 =2;
    const ERROR_YOU_ARE_NOT_OWNER: u64 = 3;
    const ERROR_INVALID_TIME :u64 = 4;


    // =================== Structs ===================

    
    /// We will keep the percentages and balances of Heirs here.
    /// 
    /// # Arguments
    /// 
    /// * `heirs_percentage` - admin will decide heirs percantage here. 
    /// * `heirs_amount` -  We keep the heirs Balance here like Table<address, <String, Balance<T>>>
    /// * `old_heirs` - We keep the heirs address in a vector for using in while loop.
    struct Legacy has key {
        id: UID,
        owner: address,
        heirs_percentage: Table<address, u64>, 
        heirs_amount: Table<address, Bag>,    
        old_heirs: vector<address>,
        remaining: u64
    } 

    // =================== Initializer ===================

    // =================== Functions ===================

    public fun new_legacy(remaining: u64, clock: &Clock, ctx: &mut TxContext) {
        let remaining_ :u64 = 1 + timestamp_ms(clock);
        //let remaining_ :u64 = ((remaining) * (86400 * 30)) + timestamp_ms(clock);
        // share object
        transfer::share_object(
            Legacy {
                id:object::new(ctx),
                owner: sender(ctx),
                heirs_percentage:table::new(ctx),
                heirs_amount:table::new(ctx),
                old_heirs:vector::empty(),
                remaining: remaining_
            },
        );
    }

    // Deposit any token for legacy
    public fun deposit_legacy<T>(kiosk: &mut Kiosk, coin:Coin<T>, coin_metadata: &CoinMetadata<T>) {
        // set the witness
        let witness = get_witness();
        // get user bag from kiosk
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(witness, kiosk);
        // convert coin to the balance
        let balance = coin::into_balance(coin);
        // define the name of coin
        let name = coin::get_name(coin_metadata);
        // we should create a key value pair in our bag for first time.
        let coin_names = string::utf8(b"coins");
        // check if coin_names vector key value is not in bag create one time.
        if(!bag::contains(bag_, coin_names)) {
            bag::add<String, vector<String>>(bag_, coin_names, vector::empty());
        };
        // lets check is there any same token in our bag
        if(bag::contains(bag_, name)) { 
        // if there is a same token in our bag we will sum it.
            let coin_value = bag::borrow_mut( bag_, name);
            balance::join(coin_value, balance);
        }
        // if it is not lets add it.
        else {
             // add fund into the bag 
             bag::add(bag_, name, balance);
             // get coins vector from bag 
             let coins = bag::borrow_mut<String, vector<String>>(bag_, coin_names);
             // Add coins name into the vector
             vector::push_back(coins, name);
        }
    }
    // Users can set new heirs
    public fun new_heirs(legacy: &mut Legacy, heir_address:vector<address>, heir_percentage:vector<u64>, ctx: &mut TxContext) {
        // check the shareobject owner
        assert!(legacy.owner == sender(ctx), ERROR_YOU_ARE_NOT_OWNER);
        // check input length >= 1 
        assert!((vector::length(&heir_address) >= 1 && 
        vector::length(&heir_address) == vector::length(&heir_percentage)), 
        ERROR_INVALID_ARRAY_LENGTH);
        // check percentange sum must be equal to 100 "
        let percentage_sum:u64 = 0;
        // remove the old heirs
        while(!vector::is_empty(&legacy.old_heirs)) {
            // Remove the old heirs from table. 
            let heir_address = vector::pop_back(&mut legacy.old_heirs);
            table::remove(&mut legacy.heirs_percentage, heir_address);
        };
         // add shareholders to table. 
        while(!vector::is_empty(&heir_address)) {
            let heir_address = vector::pop_back(&mut heir_address); 
            let heir_percentage = vector::pop_back(&mut heir_percentage);
            // add new heirs to old heirs vector. 
            vector::push_back(&mut legacy.old_heirs, heir_address);   
            // add table to new heirs and theirs percentange
            table::add(&mut legacy.heirs_percentage, heir_address , heir_percentage);
             // sum percentage
            percentage_sum = percentage_sum + heir_percentage;
        };
            // check percentage is equal to 100.
            assert!(percentage_sum == 10000, ERROR_INVALID_PERCENTAGE_SUM);
    }
    // only admin can distribute the legacy if 1 month has passed
    public fun distribute<T>(
        _: &AdminCap,
        legacy: &mut Legacy,
        kiosk: &mut Kiosk,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // check the remaining is more than 1 month
        assert!(timestamp_ms(clock) >= legacy.remaining, ERROR_INVALID_TIME);
        // set the witness
        let witness = get_witness();
        // get user bag from kiosk
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(witness, kiosk);
        // get the coin names
        let coin_names = string::utf8(b"coins");

        let coins = bag::borrow_mut<String, vector<String>>(bag_, coin_names);
        let heirs = legacy.old_heirs;

        let coin_name = vector::remove(coins, 0);
        let heirs_length = vector::length(&legacy.old_heirs); 

        let j: u64 = 0;
        // set the total balance
        let total_balance = bag::borrow<String, Balance<T>>(bag_, coin_name);
        // define the total balance as u64
        let total_amount = balance::value(total_balance);

            while(j < heirs_length) {
                // take address from oldshareholder vector
                let heir_address = vector::borrow(&heirs, j);
                if (!table::contains(&legacy.heirs_amount, *heir_address)) {
                    let bag = bag::new(ctx);
                    table::add(&mut legacy.heirs_amount,*heir_address,bag);
                 };  
                // take heir percentage from table
                let heir_percentage = table::borrow(&legacy.heirs_percentage, *heir_address);
                // set the total balance
                let total_balance = bag::borrow_mut<String, Balance<T>>(bag_, coin_name);
                // calculate heir withdraw tokens
                let heir_legacy =  (total_amount * *heir_percentage ) / 10000;
                // calculate the distribute coin value to shareholder           
                let withdraw_coin = balance::split<T>( total_balance, heir_legacy);
                // get heir's bag from share object
                let heir_bag = table::borrow_mut<address, Bag>( &mut legacy.heirs_amount, *heir_address);
                // add heir's amount to table
                if(bag::contains(heir_bag, coin_name) == true) { 
                    let coin_value = bag::borrow_mut( heir_bag, coin_name);
                    balance::join(coin_value, withdraw_coin);
                }   else { 
                        bag::add(heir_bag, coin_name, withdraw_coin);
                     };
                j = j + 1;
            };       
    }
    // Heirs can withdraw funds
    public fun withdraw<T>(legacy: &mut Legacy, coin_name: String, ctx: &mut TxContext) : Coin<T> {
        let sender = sender(ctx);
        // firstly, check that  Is sender shareholder? 
        assert!(
           table::contains(&legacy.heirs_amount, sender),
            ERROR_YOU_ARE_NOT_HEIR
        );
        // let take heir's bag from table 
        let bag_ = table::borrow_mut<address, Bag>(&mut legacy.heirs_amount, sender);
        // calculate withdraw balance 
        let balance_value = bag::remove<String, Balance<T>>( bag_, coin_name);
        // return the withdraw balance
        let coin_value = coin::from_balance(balance_value, ctx);
        coin_value
    }

    // TEST ONLY
    #[test_only]
    // It is the same function with deposit_to_bag but we cant read sui token metadata. So we have to split it. 
    public fun deposit_legacy_sui(kiosk: &mut Kiosk, coin:Coin<SUI>) {
        // set the witness
        let witness = get_witness();
        // get user bag from kiosk
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(witness, kiosk);
        // lets define balance
        let balance = coin::into_balance(coin);
        // set the sui as a string
        let name = string::utf8(b"sui");
        // we should create a key value pair in our bag for first time.
        let coin_names = string::utf8(b"coins");
        // check if coin_names vector key value is not in bag create one time.
        if(!bag::contains(bag_, coin_names)) {
            bag::add<String, vector<String>>(bag_, coin_names, vector::empty());
        };
        // lets check is there any sui token in bag
        if(bag::contains(bag_, name)) { 
            let coin_value = bag::borrow_mut(bag_, name);
             // if there is a sui token in our bag we will sum it.
             balance::join(coin_value, balance);
        }
        else { 
            // add fund into the bag 
            bag::add(bag_, name, balance);
            let coins = bag::borrow_mut<String, vector<String>>(bag_, coin_names);
            // Add coins name into the vector
            vector::push_back(coins, name);
        }
    }

    #[test_only]
    public fun test_get_heir_balance<T>(legacy: &Legacy, heir: address, coin: String) : u64 {
        let bag_ = table::borrow<address, Bag>(&legacy.heirs_amount, heir);
        let coin = bag::borrow<String, Balance<T>>(bag_, coin);
        let amount = balance::value(coin);
        amount
    }
    #[test_only]
    public fun test_get_remaining(legacy: &Legacy) : u64 {
        legacy.remaining
    }
}
