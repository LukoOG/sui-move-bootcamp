module my_first_move_package::my_first_move_package;

use sui::transfer::{ public_transfer };

public struct LagosHero has key, store {
	id: UID
}

public fun mint_hero( ctx: &mut TxContext ): LagosHero{
	let hero = LagosHero{
		id: object::new(ctx)
	};
	hero
}

public entry fun mint_and_keep(ctx: &mut TxContext  ){
	let hero = mint_hero(ctx);
	public_transfer(hero, ctx.sender())
}