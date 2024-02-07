module notary::lira_stable_coin {
  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::{Self, Coin, TreasuryCap};

  // === Friends ===

  friend notary::assets_operation;
 
  // === Structs ===  

  struct TR_LIRA has drop {}

  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<TR_LIRA>
  }

  // === Init ===  

  #[lint_allow(share_owned)]
  fun init(witness: TR_LIRA, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<TR_LIRA>(
            witness, 
            9, 
            b"LIRA",
            b"TR_LIRA", 
            b"Stable coin issued by Turkey Goverment", 
            option::none(), 
            ctx
        );

      transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury_cap });
      transfer::public_share_object(metadata);
  }

  // === Public-Mutative Functions ===  

  public fun burn(cap: &mut CapWrapper, coin_in: Coin<TR_LIRA>): u64 {
    coin::burn(&mut cap.cap, coin_in)
  }

  // === Public-Friend Functions ===  

  public(friend) fun mint(cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<TR_LIRA> {
    coin::mint(&mut cap.cap, value, ctx)
  }

  // === Test Functions ===  

  #[test_only]
  public fun return_init_sui_dollar(ctx: &mut TxContext) {
    init(TR_LIRA {}, ctx);
  }










}