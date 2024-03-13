module notary::lira {
  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::{Self, Coin, TreasuryCap};

  // === Friends ===

  // === Structs ===  

  struct LIRA has drop {}

  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<LIRA>
  }

  // === Init ===  

  #[lint_allow(share_owned)]
  fun init(witness: LIRA, ctx: &mut TxContext) {
      let (treasury, metadata) = coin::create_currency<LIRA>(
            witness, 
            9, 
            b"LIRA",
            b"Tr Lira", 
            b"Stable coin issued by Turkey Goverment", 
            option::none(), 
            ctx
        );

      transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury });
      transfer::public_freeze_object(metadata);
  }

  // === Public-Mutative Functions ===  

  public fun burn(cap: &mut CapWrapper, coin_in: Coin<LIRA>): u64 {
    coin::burn(&mut cap.cap, coin_in)
  }

  // === Public-Friend Functions ===  

  public fun mint(cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<LIRA> {
    coin::mint(&mut cap.cap, value, ctx)
  }

  // === Test Functions ===  

  #[test_only]
  public fun return_init_lira(ctx: &mut TxContext) {
    init(LIRA {}, ctx);
  }
}
