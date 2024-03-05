module notary::assets_legacy {
    use sui::object::{Self, UID, ID};
    use sui::table::{Self, Table};
    use sui::bag::{Self, Bag};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use sui::kiosk::{Self, Kiosk, PurchaseCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::balance::{Self};
    use sui::sui::{SUI};

    use notary::assets_type::{NotaryKioskExtWitness, get_witness};

    use std::vector;
    use std::string;

    // =================== Errors ===================

    const ERROR_INVALID_ARRAY_LENGTH: u64 = 0;
    const ERROR_INVALID_PERCENTAGE_SUM: u64 = 1;
    const ERROR_YOU_ARE_NOT_SHAREHOLDER:u64 =2;
    const ERROR_FUNCTION_DISABLED:u64 = 3;
    const ERROR_YOU_ARE_NOT_OWNER:u64 = 4;


    // =================== Structs ===================

    
    /// We will keep the percentages and balances of Heirs here.
    /// 
    /// # Arguments
    /// 
    /// * `shareholders_percentage` - admin will decide shareholder percantage here. 
    /// * `shareholders_amount` -  We keep the shareholders Balance here like Table<address, <String, Balance<T>>>
    /// * `old_shareholders` - We keep the shareholders address in a vector for using in while loop.
    struct Legacy has key {
        id: UID,
        owner: address,
        heirs_percentage: Table<address, u64>, 
        heirs_amount: Table<address, Bag>,    
        old_heirs: vector<address>,
    } 

    // =================== Initializer ===================

    fun init(ctx:&mut TxContext) {

    }

    // =================== Functions ===================

    public fun new_legacy(ctx: &mut TxContext) {
        // share object
        transfer::share_object(
            Legacy {
                id:object::new(ctx),
                owner: sender(ctx),
                heirs_percentage:table::new(ctx),
                heirs_amount:table::new(ctx),
                old_heirs:vector::empty(),
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
        // lets check is there any same token in our bag
        if(bag::contains(bag_, name)) { 
        // if there is a same token in our bag we will sum it.
            let coin_value = bag::borrow_mut( bag_, name);
            balance::join(coin_value, balance);
        }
            // if it is not lets add it.
        else { 
             bag::add(bag_, name, balance);
        }
    }
    // It is the same function with deposit_to_bag but we cant read sui token metadata. So we have to split it. 
    public fun deposit_legacy_sui(kiosk: &mut Kiosk, coin:Coin<SUI>) {
        // set the witness
        let witness = get_witness();
        // get user bag from kiosk
        let bag_ = ke::storage_mut<NotaryKioskExtWitness>(witness, kiosk);
        // lets define balance
        let balance = coin::into_balance(coin);
        // set the sui as a string
        let name_string = string::utf8(b"sui");
            // lets check is there any sui token in bag
        if(bag::contains(bag_, name_string)) { 
            let coin_value = bag::borrow_mut(bag_, name_string);
            // if there is a sui token in our bag we will sum it.
             balance::join(coin_value, balance);
        }
        else { 
             // if it is not lets add it.
            bag::add(bag_, name_string, balance);
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























}