module notary::assets_renting {

    use std::string::{String};
    
    use sui::tx_context::{TxContext, sender};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::kiosk::{Self, Kiosk, PurchaseCap};
    use sui::table::{Self, Table};
    use sui::transfer_policy::{Self as policy, TransferPolicy};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Clock, timestamp_ms}; 
    // use sui::transfer_policy::{Self as policy, TransferPolicy};

    use notary::assets::{Self, Asset};
    use notary::assets_type::{Self as at, ListedTypes};

    // =================== Errors ===================

    const ERROR_NOT_APPROVED: u64 = 1;
    const ERROR_NOT_KIOSK_OWNER: u64 = 2;
    const ERROR_ASSET_IN_RENTING: u64 = 3;
    const ERROR_INVALID_PRICE : u64 = 4;

    // =================== Structs ===================

    struct Contracts has key {
        id: UID,
        contracts: Table<address, Contract>,
        complaints: Table<address, Complaint>,
        purchase_cap: Table<ID, PurchaseCap<Asset>>
    }

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

    struct Complaint has store, copy, drop {
        complainant: address,
        pleader: address,
        reason: String,
        decision: bool,
        active: bool
    }

    // =================== Initializer ===================

    fun init(ctx: &mut TxContext) {
        // share the Contracts
        transfer::share_object(Contracts{
            id: object::new(ctx),
            contracts: table::new(ctx),
            complaints: table::new(ctx),
            purchase_cap: table::new<ID, PurchaseCap<Asset>>(ctx), 
        });
    }

    // =================== Functions ===================

    // list the asset for spesific address
    public fun list_with_purchase_cap(
        share: &mut ListedTypes,
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
        let asset = kiosk::borrow<Asset>(kiosk, kiosk_cap, asset_id);
        assert!(assets::is_approved(asset), ERROR_NOT_APPROVED);
        assert!(!assets::is_renting(asset), ERROR_ASSET_IN_RENTING);
        let purch_cap = kiosk::list_with_purchase_cap<Asset>(
            kiosk,
            kiosk_cap,
            asset_id,
            price,
            ctx
        );
        // send the purchase_cap to leaser
        transfer::public_transfer(purch_cap, buyer);
    }
    // rent the asset
    public fun rent(
        share: &mut Contracts,
        listed_types: &ListedTypes,
        owner_kiosk: &mut Kiosk,
        leaser_kiosk: &mut Kiosk,
        policy: &TransferPolicy<Asset>,
        purch_cap: PurchaseCap<Asset>,
        asset_id: ID,
        payment: Coin<SUI>, // it should be equal to 1 month rental price + deposit price 
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
        let (asset, request) = kiosk::purchase_with_cap<Asset>(
            owner_kiosk,
            purch_cap,
            payment_purchase
        );
        // confirm the request. Destroye the hot potato
        policy::confirm_request(policy, request);
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(leaser_kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // calculate the end time as a second
        let end_time: u64 = (86400 * 30) * (rental_period);
        // set the contract
        let contract = Contract {
            id: object::new(ctx),
            owner: kiosk::owner(leaser_kiosk),
            leaser: sender(ctx),
            item: asset_id,
            deposit: coin::into_balance(payment),
            rental_period:rental_period,
            rental_count: 1, 
            start: timestamp_ms(clock),
            end: end_time 
        };
        // keep the contract in protocol
        table::add( &mut share.contracts, kiosk::owner(leaser_kiosk), contract);
         // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(leaser_kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // set the on_rent variable to true
        assets::active_rent(&mut asset);
        // place the asset into the kiosk
        let kiosk_cap = at::get_cap(listed_types, sender(ctx));
        // place the item into the leaser kiosk
        kiosk::place(leaser_kiosk, kiosk_cap, asset);
        // list the asset and keep the pruch_cap in protocol
        let leaser_purch_cap = kiosk::list_with_purchase_cap<Asset>(
            leaser_kiosk,
            kiosk_cap,
            asset_id,
            1,
            ctx
        );
        table::add(&mut share.purchase_cap, asset_id, leaser_purch_cap);        
    }
    // owner take the asset back
    public fun get_asset(
        listed: &ListedTypes,
        share: &mut Contracts,
        kiosk: &mut Kiosk,
        purch_cap: PurchaseCap<Asset>,
        policy: &TransferPolicy<Asset>,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // get the contract between owner and leaser 
        let contract = table::borrow_mut(&mut share.contracts, sender(ctx));
        if((timestamp_ms(clock) - (contract.start)) % ((86400 * 30)) >= contract.rental_count) {
            unpaid_rent(listed, share, kiosk, purch_cap, policy, payment, ctx);
        }
        else { 
        // check the time
        assert!(timestamp_ms(clock) >= contract.end, ERROR_ASSET_IN_RENTING);
        // get kioskcap
        let kiosk_cap = at::get_cap(listed, sender(ctx));

        let(asset, request) = kiosk::purchase_with_cap<Asset>(
            kiosk,
            purch_cap,
            payment,
        );
        // confirm the request
        policy::confirm_request(policy, request);
        // place the asset into the kiosk
        kiosk::place(kiosk, kiosk_cap, asset);
        // return the contract_balance as u64
        let contract_value = balance::value(&contract.deposit);
        // take the all balance from contract_ deposit
        let contract_balance = balance::split(&mut contract.deposit, contract_value);
        // change balance into the Coin
        let deposit = coin::from_balance(contract_balance, ctx);
        // transfer the deposit to owner
        transfer::public_transfer(deposit, contract.owner);
        };
    } 
    // owner or leaser can create complain
    public fun complain() {

    }
    // admin should judge the complain
    public fun provision() {

    }

    // =================== Helper Functions ===================

    // if the leaser couldn't pay his rent give the asset to owner 
    fun unpaid_rent(
        listed: &ListedTypes,
        share: &mut Contracts,
        kiosk: &mut Kiosk,
        purch_cap: PurchaseCap<Asset>,
        policy: &TransferPolicy<Asset>,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // be sure that sender is the owner of kiosk
        assert!(kiosk::owner(kiosk) == sender(ctx), ERROR_NOT_KIOSK_OWNER);
        // get the contract between owner and leaser 
        let contract = table::borrow_mut(&mut share.contracts, sender(ctx));
        // get kioskcap
        let kiosk_cap = at::get_cap(listed, sender(ctx));

        let(asset, request) = kiosk::purchase_with_cap<Asset>(
            kiosk,
            purch_cap,
            payment,
        );
        // confirm the request
        policy::confirm_request(policy, request);
        // place the asset into the kiosk
        kiosk::place(kiosk, kiosk_cap, asset);
        // return the contract_balance as u64
        let contract_value = balance::value(&contract.deposit);
        // take the all balance from contract_ deposit
        let contract_balance = balance::split(&mut contract.deposit, contract_value);
        // change balance into the Coin
        let deposit = coin::from_balance(contract_balance, ctx);
        // transfer the deposit to owner
        transfer::public_transfer(deposit, contract.owner);
    }
    

    // =================== Test Only ===================


}