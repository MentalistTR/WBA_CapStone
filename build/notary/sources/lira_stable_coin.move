module notary::lira_stable_coin {
  use std::option;

  use sui::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::coin::{Self, Coin, TreasuryCap};

  // === Friends ===

  friend notary::assets_operation;
 
  // === Structs ===  

  struct LIRA_STABLE_COIN has drop {}

  struct CapWrapper has key {
    id: UID,
    cap: TreasuryCap<LIRA_STABLE_COIN>
  }

  // === Init ===  

  #[lint_allow(share_owned)]
  fun init(witness: LIRA_STABLE_COIN, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<LIRA_STABLE_COIN>(
            witness, 
            9, 
            b"LIRA",
            b"Tr Lira", 
            b"Stable coin issued by Turkey Goverment", 
            option::none(), 
            ctx
        );

      transfer::share_object(CapWrapper { id: object::new(ctx), cap: treasury_cap });
      transfer::public_share_object(metadata);
  }

  // === Public-Mutative Functions ===  

  public fun burn(cap: &mut CapWrapper, coin_in: Coin<LIRA_STABLE_COIN>): u64 {
    coin::burn(&mut cap.cap, coin_in)
  }

  // === Public-Friend Functions ===  

  public(friend) fun mint(cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<LIRA_STABLE_COIN> {
    coin::mint(&mut cap.cap, value, ctx)
  }

  // === Test Functions ===  

  #[test_only]
  public fun return_init_sui_dollar(ctx: &mut TxContext) {
    init(LIRA_STABLE_COIN {}, ctx);
  }
}
