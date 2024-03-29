/// Assets Sales module is responsible for renting the Asset and contracts
/// 
/// There are four main operations in this module:
/// 
/// 1. Users can list any asset
/// 2. Users can rent the asset
/// 3. Users can create complain
/// 4. Admin can provision if there is a problem between leaser and owner
module notary::assets_renting {
    use std::string::{String};
    use std::vector;

    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::kiosk::{Self, Kiosk, PurchaseCap};
    use sui::kiosk_extension::{Self as ke};
    use sui::table::{Self, Table};
    use sui::bag::{Self};
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Clock, timestamp_ms}; 

    use notary::assets::{Self, Asset, Wrapper};
    use notary::assets_type::{Self as at, ListedTypes, AdminCap, NotaryKioskExtWitness};
    
    use rules::loan_duration::{Self as ld};
    use rules::time_duration::{Self as td};
    use rules::royalty_rule::{Self as rr, NotaryFee};
    use rules::lira::{LIRA};

    // =================== Errors ===================

    const ERROR_NOT_APPROVED: u64 = 1;
    const ERROR_NOT_KIOSK_OWNER: u64 = 2;
    const ERROR_ASSET_IN_RENTING: u64 = 3;
    const ERROR_INVALID_PRICE : u64 = 4;
    const ERROR_INCORRECT_LEASER: u64 = 5;
    const ERROR_NOT_ASSET_OWNER: u64 = 6;
    const ERROR_INVALID_DURATION: u64 = 7;

    // =================== Structs ===================

    // The shareobject that we keep complaints and purchaseCaps in the module.
    struct Contracts has key {
        id: UID,
        complaints: Table<ID, Complaint>,
        purchase_cap: Table<ID, PurchaseCap<Wrapper>>,
        wrapper: vector<ID> // FIXME: DELETE ME !! 
    }
    // Contract is the aggrement between leaser and owner 
    // We will keep 1 month deposit amount, item_id and rental periods. 
    struct Contract has key, store {
        id: UID,
        owner: address,
        leaser: address,
        item: ID,
        deposit: Balance<SUI>,
        rental_period: u64,
        rental_count: u64,
        start: u64,
        end: u64, 
    }
    // Leaser or owner can create an comlaint
    struct Complaint has store, copy, drop {
        complainant: address,
        pleader: address,
        reason: String,
        decision: bool,
    }

    // =================== Initializer ===================

    fun init(ctx: &mut TxContext) {
        // share the Contracts
        transfer::share_object(Contracts{
            id: object::new(ctx),
            complaints: table::new(ctx),
            purchase_cap: table::new<ID, PurchaseCap<Wrapper>>(ctx),
            wrapper: vector::empty()
        });
    }

    // =================== Functions ===================

    /// Users can list the asset for to specific address
    /// 
    /// # Arguments
    /// 
    /// * `share` - the shareobject that we reach to kioskownerCap
    /// * `kiosk` - defines the user's kiosk
    /// * `price` - the asset's 1 monthly price 
    /// * `buyer` - the address of leaser 
    public fun list_with_purchase_cap(
        share: &mut ListedTypes,
        contract: &mut Contracts,
        kiosk: &mut Kiosk,
        asset_id: ID,
        price: u64,
        buyer: address,
        ctx: &mut TxContext
    ) {
        // check the kiosk owner
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // set the kiosk cap 
        let kiosk_cap = at::get_cap(share, sender(ctx));
         // borrow the asset 
        let asset = kiosk::take<Asset>(kiosk, kiosk_cap, asset_id);
        assert!(assets::is_approved(&asset), ERROR_NOT_APPROVED);
        assert!(!assets::is_renting(&asset), ERROR_ASSET_IN_RENTING);
        // wrap the asset 
        let wrapper = assets::wrap(asset, ctx);
        // define the wrapper id 
        let wrapper_id = object::id(&wrapper);
        // keep wrapper id for local test  
        vector::push_back(&mut contract.wrapper, wrapper_id);  // FIXME: DELETE ME !!
        // place the wrapper into the kiosk
        kiosk::place(kiosk, kiosk_cap, wrapper);
        
        let purch_cap = kiosk::list_with_purchase_cap<Wrapper>(
            kiosk,
            kiosk_cap,
            wrapper_id,
            price,
            ctx
        );
        // send the purchase_cap to leaser
        transfer::public_transfer(purch_cap, buyer);
    }
    /// Users can rent the wrapped asset if they had purchasecap
    /// 
    /// # Arguments
    /// 
    /// * `share` - the shareobject that we keep the purchasecap
    /// * `listed_types` - the shareobject that we keep the KioskOwnerCap
    /// * `notary` - the storage for notary's fee.
    /// * `purch_cap` - the purch_cap that leaser can rent the wrapped asset
    /// * `payment` - the sum of 1 month price and deposit price
    /// * `fee` - the notary fee for every process 
    /// * `rental_period` - the rental month date
    /// * `clock` - the share object that we initiliaze the current time.
    public fun rent(
        share: &mut Contracts,
        listed_types: &ListedTypes,
        notary: &mut NotaryFee,
        owner_kiosk: &mut Kiosk,
        leaser_kiosk: &mut Kiosk,
        policy: &TransferPolicy<Wrapper>,
        purch_cap: PurchaseCap<Wrapper>,
        wrapper_id: ID,
        payment: Coin<SUI>, // it should be equal to 1 month rental price + deposit price 
        fee: Coin<LIRA>,
        rental_period: u64,
        clock: &Clock,
        ctx: &mut TxContext 
    ) {
        // calculate the payment. It should be greater or equal to total renting price.
        assert!(
            coin::value(&payment) >= (kiosk::purchase_cap_min_price(&purch_cap) * 2), ERROR_INVALID_PRICE);
        // coin for put to purchase_with_cap
        let payment_purchase = coin::split(&mut payment, (kiosk::purchase_cap_min_price(&purch_cap)), ctx);
        // purchase the asset from kiosk
        let (wrapper, request) = kiosk::purchase_with_cap<Wrapper>(
            owner_kiosk,
            purch_cap,
            payment_purchase
        );
        ld::prove<Wrapper>(policy, &mut request, owner_kiosk, rental_period);
        rr::pay<Wrapper>(policy, &mut request, notary, fee, ctx);
        // confirm the request. Destroye the hot potato
        policy::confirm_request(policy, request);
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(leaser_kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // // calculate the end time as a second
        let end_time: u64 = ((86400 * 30) * (rental_period) + timestamp_ms(clock));
        // set to testnet 
       // let end_time: u64 = timestamp_ms(clock) + 20;

        // set the contract
        let contract = Contract {
            id: object::new(ctx),
            owner: kiosk::owner(owner_kiosk),
            leaser: sender(ctx),
            item: wrapper_id,
            deposit: balance::zero(),
            rental_period:rental_period,
            rental_count: 1, 
            start: timestamp_ms(clock),
            end: end_time 
        };
        // merge the two balance
        balance::join(&mut contract.deposit, coin::into_balance(payment));
        // define the witness
        let witness = at::get_witness();
        // keep the contract in owner's bag
        let owner_bag = ke::storage_mut<NotaryKioskExtWitness>(witness, owner_kiosk);
        bag::add<ID,Contract>( owner_bag, wrapper_id, contract);
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(leaser_kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // place the asset into the kiosk
        let kiosk_cap = at::get_cap(listed_types, sender(ctx));
        // place the item into the leaser kiosk
        kiosk::place(leaser_kiosk, kiosk_cap, wrapper);
        // list the asset and keep the pruch_cap in protocol
        let leaser_purch_cap = kiosk::list_with_purchase_cap<Wrapper>(
            leaser_kiosk,
            kiosk_cap,
            wrapper_id,
            1,
            ctx
        );
        table::add(&mut share.purchase_cap, wrapper_id, leaser_purch_cap);        
    }
    /// Users can deposit rental monthly price 
    /// 
    /// # Arguments
    /// 
    /// * `owner_kiosk` - the asset's owner kiosk
    /// * `payment` - the amount of 1 monthly rental price 
    /// * `item_id` - the wrapped object id
    public fun pay_monthly_rent(owner_kiosk: &mut Kiosk, payment: Coin<SUI>, item_id: ID, ctx: &mut TxContext) {
        let witness = at::get_witness();
        // get the owner's bag
        let owner_bag = ke::storage_mut(witness, owner_kiosk);
        // get the contract_mut
        let contract = bag::borrow_mut<ID, Contract>(owner_bag, item_id);
        // check the rental count. It should be lower than 12
        assert!(contract.rental_count < 12, ERROR_INVALID_DURATION);
        // check the payment price 
        assert!(coin::value(&payment) >= (balance::value(&contract.deposit)), ERROR_INVALID_PRICE);
        // check the leaser address
        assert!(sender(ctx) == contract.leaser, ERROR_INCORRECT_LEASER);
        // increment the rental count 
        contract.rental_count = contract.rental_count + 1;
        // transfer payment to owner of asset 
        transfer::public_transfer(payment, contract.owner); 
    }
    /// Asset's owner can get asset
    /// Theere are two condition. First one is the unpaid rent
    /// Second is the rental period 
    /// 
    /// # Arguments
    /// 
    /// * `listed_types` - the shareobject that we keep the KioskOwnerCap
    /// * `share` - the shareobject that we keep the purchasecap
    /// * `policy` - the transferPolicy for the rules
    /// * `payment` - The zero sui for execute the function
    /// * `clock` - the share object that we initiliaze the current time.
    public fun get_asset(
        listed: &ListedTypes,
        share: &mut Contracts,
        kiosk1: &mut Kiosk,
        kiosk2: &mut Kiosk,
        wrapper_id : ID,
        policy: &TransferPolicy<Wrapper>,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(kiosk1) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // get the contract between owner and leaser 
        let witness = at::get_witness();
        // get the owner's bag
        let owner_bag = ke::storage_mut(witness, kiosk1);
        // get the contract_mut
        let contract = bag::borrow_mut<ID, Contract>(owner_bag, wrapper_id);
        let contract_end = contract.end;
        let contract_start = contract.start; 
        let contract_rental = contract.rental_count;

        assert!(sender(ctx) == contract.owner, ERROR_NOT_ASSET_OWNER);

        let purch_cap = table::remove(&mut share.purchase_cap, wrapper_id);

        if((timestamp_ms(clock) - (contract_start)) / ((86400 * 30)) + 1 > contract_rental) {
            unpaid_rent(listed, kiosk1, kiosk2, wrapper_id, purch_cap, policy, payment, clock, contract_end, contract_start, contract_rental, ctx);
        }
        else { 
        // check the time
        assert!(timestamp_ms(clock) >= contract_end, ERROR_ASSET_IN_RENTING);
        // get kioskcap
        let kiosk_cap = at::get_cap(listed, sender(ctx));
        // purchase the wrapped asset
        let(wrapper, request) = kiosk::purchase_with_cap<Wrapper>(
            kiosk2,
            purch_cap,
            payment,
        );
        td::prove<Wrapper>(policy, &mut request, clock, contract_end, contract_start, contract_end);
        // confirm the request
        policy::confirm_request(policy, request);
        //destructure the wrapp
        let asset = assets::unwrap(wrapper);
        // disable the on_rent boolean
        assets::disable_rent(&mut asset);
        // return the contract_balance as u64
        let contract_value = (balance::value(&contract.deposit));
        // take the all balance from contract_ deposit
        let contract_balance = balance::split(&mut contract.deposit, contract_value);
        // change balance into the Coin
        let deposit = coin::from_balance(contract_balance, ctx);
        // transfer the deposit to owner
        transfer::public_transfer(deposit, contract.leaser);
        // place the asset into the kiosk
        kiosk::place(kiosk1, kiosk_cap, asset);
        };
    } 
    /// Leaser or owner can create complain if there is a problem about asset
    /// 
    /// # Arguments
    /// 
    /// * `share` - the shareobject that we keep the complains
    /// * `owner_kiosk` - the asset's owner kiosk
    /// * `reason_` - defines the problem
    public fun new_complain(share: &mut Contracts, owner_kiosk: &mut Kiosk, reason_: String, wrapper_id: ID, ctx: &mut TxContext) {
        // define the witness
        let witness = at::get_witness();
        // get the owner's bag
        let owner_bag = ke::storage_mut(witness, owner_kiosk);
        // get the contract_mut
        let contract = bag::borrow_mut<ID, Contract>(owner_bag, wrapper_id);
        let leaser = contract.leaser;
        let owner = contract.owner;
        let pleader = sender(ctx);

        assert!(leaser == sender(ctx) || owner == sender(ctx), ERROR_INCORRECT_LEASER);

        if(sender(ctx) == leaser) {
            let pleader = owner;
        } else {
            let pleader = leaser;
        };
        // define the complain
        let complain_ = Complaint{
            complainant: sender(ctx),
            pleader: pleader,
            reason: reason_,
            decision: false,
        };
        table::add(&mut share.complaints, wrapper_id, complain_);
    }
    /// admin must decide to who is right
    /// 
    /// # Arguments
    /// 
    /// * `share` - the shareobject that we keep the complains
    /// * `owner_kiosk` - the asset's owner kiosk
    /// * `decision` - the bool type for provision
    public fun provision(
        _: &AdminCap,
        share: &mut Contracts,
        owner_kiosk: &mut Kiosk,
        wrapper_id : ID,
        decision: bool,
    ) {
        let witness = at::get_witness();
        // get the owner's bag
        let owner_bag = ke::storage_mut(witness, owner_kiosk);
        // get the contract_mut
        let contract = bag::borrow_mut<ID, Contract>(owner_bag, wrapper_id);
        // remove the complain from table
        let complain = table::remove(&mut share.complaints, wrapper_id);

        let leaser = contract.leaser;
        let complainant_ = complain.complainant;

        // if admin decide true these conditions should execute. If it is false nothing happen.
        if(decision == true) { 
            if(leaser == complainant_) {
            contract.rental_count = contract.rental_count + 1;
            } else {
            contract.rental_count = contract.rental_count - 1;
            }; 
        }
    }

    // =================== Helper Functions ===================

    // Helper function that we use in get_asset function to condition 1
    fun unpaid_rent(
        listed: &ListedTypes,
        kiosk1: &mut Kiosk,
        kiosk2: &mut Kiosk,
        item_id : ID,
        purch_cap: PurchaseCap<Wrapper>,
        policy: &TransferPolicy<Wrapper>,
        payment: Coin<SUI>,
        clock: &Clock,
        contract_end: u64,
        contract_start: u64,
        contract_rental: u64,
        ctx: &mut TxContext
    ) {
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(kiosk1) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // get kioskcap
        let kiosk_cap = at::get_cap(listed, sender(ctx));

        let(wrapper, request) = kiosk::purchase_with_cap<Wrapper>(
            kiosk2,
            purch_cap,
            payment,
        );
        td::prove<Wrapper>(policy, &mut request, clock, contract_end, contract_start, contract_rental);
        // confirm the request
        policy::confirm_request(policy, request);
        //destructure the wrapp
        let asset = assets::unwrap(wrapper);
        // disable the on_rent boolean
        assets::disable_rent(&mut asset);
        // place the asset into the kiosk
        kiosk::place(kiosk1, kiosk_cap, asset);
        // define the witness
        let witness = at::get_witness();
        // get owner's bag from his kiosk   
        let owner_bag = ke::storage_mut(witness, kiosk1);
        // get contract from owners' bag
        let contract = bag::borrow_mut<ID, Contract>(owner_bag, item_id);
        assert!(sender(ctx) == contract.owner, ERROR_NOT_ASSET_OWNER); 
        // return the contract_balance as u64
        let contract_value = (balance::value(&contract.deposit));
        // take the all balance from contract_ deposit
        let contract_balance = balance::split(&mut contract.deposit, contract_value);
        // change balance into the Coin
        let deposit = coin::from_balance(contract_balance, ctx);
        // transfer the deposit to owner
        transfer::public_transfer(deposit, contract.owner);
    }
    
    // =================== Test Only ===================
    #[test_only]
    // call the init function
    public fun test_renting_init(ctx: &mut TxContext) {
        init( ctx);
    }
    #[test_only]
    // call the init function
    public fun test_get_contract_rental_count(self: &Kiosk, item_id: ID) : u64 {
        let witness = at::get_witness();   
        let owner_bag = ke::storage(witness, self);
        let contract = bag::borrow<ID, Contract>(owner_bag, item_id);
        contract.rental_count
    }
    #[test_only]
    // get wrapper_id
    public fun test_get_wrapper(self: &Contracts) : ID {
       let id =  vector::borrow(&self.wrapper, 0);
       *id
    }
}
