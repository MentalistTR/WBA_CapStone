// CRUD Module 
// define asset types  > House Car Land 
// define share object for listedtypes allow types 
// The admin should be able to add new transfer policy to share object
// create update and read and destroye 
module notary::assets_type {
    use std::string::{String};
    use std::vector;
    use std::type_name::{TypeName};
   // use std::debug;

    use sui::tx_context::{Self,TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::vec_set::{Self, VecSet};
    //use sui::package::{Self, Publisher};
    //use sui::transfer_policy::{Self as tp, TransferPolicy};
    //use sui::kiosk::{Self, Kiosk, KioskOwnerCap};

    // use notary::lira_stable_coin::{LIRA_STABLE_COIN};

    // use notary::assets::{Self, Asset};

    // share object 
    struct ListedTypes has key, store {
        id: UID,
        types: vector<String>,
    }

    

















}