module hero::hero;
use std::string::String;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::dynamic_object_field as dof;
use sui::sui::SUI;
use weapon::weapon::{Self, AllowList};

const EInvalidWeaponTicket: u64 = 0;
const EInsufficientFunds: u64 = 1;

const WEAPON_PRICE: u64 = 1_000_000_000;

// TODO: Declare the witness struct

public struct Treasury has key {
    id: UID,
    balance: Balance<SUI>,
}

public struct AdminCap has key {
    id: UID,
}

public struct Hero has key {
    id: UID,
    name: String,
}

public struct WeaponTicket has key {
    id: UID,
    hero_id: ID,
    weapon_name: String,
}

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };
    let treasury = Treasury {
        id: object::new(ctx),
        balance: balance::zero(),
    };

    transfer::transfer(admin_cap, ctx.sender());
    transfer::share_object(treasury);
}

public fun mint_hero(_: &AdminCap, name: String, ctx: &mut TxContext): Hero {
    Hero {
        id: object::new(ctx),
        name,
    }
}

public fun transfer_hero(_: &AdminCap, hero: Hero, to: address) {
    transfer::transfer(hero, to);
}

public fun withdraw_treasury(
    _: &AdminCap,
    treasury: &mut Treasury,
    ctx: &mut TxContext,
): Coin<SUI> {
    let balance = treasury.balance.withdraw_all();
    balance.into_coin(ctx)
}

public fun mint_weapon_ticket(
    price: Coin<SUI>,
    treasury: &mut Treasury,
    hero: &Hero,
    weapon_name: String,
    ctx: &mut TxContext,
): WeaponTicket {
    assert!(price.value() >= WEAPON_PRICE, EInsufficientFunds);
    treasury.balance.join(price.into_balance());

    WeaponTicket {
        id: object::new(ctx),
        hero_id: hero.id.to_inner(),
        weapon_name,
    }
}

public fun transfer_weapon_ticket(weapon_ticket: WeaponTicket, ctx: &mut TxContext) {
    transfer::transfer(weapon_ticket, ctx.sender());
}

public fun attach_weapon(
    hero: &mut Hero,
    weapon_ticket: WeaponTicket,
    allow_list: &AllowList,
    ctx: &mut TxContext,
) {
    // TODO: create the logic that allows the hero to attach a weapon that is minted in the external contract
}

// Test Only
#[test_only]
use weapon::weapon::{Weapon, EInvalidCaller};
#[test_only]
use sui::package::Publisher;
#[test_only]
use sui::{test_scenario as ts};
#[test_only]
use std::unit_test::assert_eq;

#[test_only]
const HERO_ADMIN: address = @0xAA;
#[test_only]
const WEAPON_ADMIN: address = @0xBB;
#[test_only]
const HERO_USER: address = @0xCC;

#[test, expected_failure(abort_code = EInvalidCaller)]
fun test_attach_weapon_fails_for_non_whitelisted_witness() {
    let mut ts = ts::begin(HERO_ADMIN);
    init(ts.ctx());

    ts.next_tx(WEAPON_ADMIN);
    {
        weapon::init_for_testing(ts.ctx());
    };

    ts.next_tx(HERO_ADMIN);
    {
        let admin_cap = ts.take_from_sender<AdminCap>();
        let hero = mint_hero(&admin_cap, b"Hero".to_string(), ts.ctx());
        transfer_hero(&admin_cap, hero, HERO_USER);
        ts.return_to_sender(admin_cap);
    };

    ts.next_tx(HERO_USER);
    {
        let mut treasury = ts.take_shared<Treasury>();
        let hero = ts.take_from_sender<Hero>();
        let weapon_ticket = mint_weapon_ticket(
            coin::mint_for_testing(WEAPON_PRICE, ts.ctx()),
            &mut treasury,
            &hero,
            b"Weapon".to_string(),
            ts.ctx(),
        );
        transfer_weapon_ticket(weapon_ticket, ts.ctx());
        ts.return_to_sender(hero);
        ts::return_shared(treasury);
    };

    ts.next_tx(HERO_USER);
    {
        let allow_list = ts.take_shared<AllowList>();
        let weapon_ticket = ts.take_from_sender<WeaponTicket>();
        let mut hero = ts.take_from_sender<Hero>();
        attach_weapon(&mut hero, weapon_ticket, &allow_list, ts.ctx());

        abort (1337)
    }
}

#[test]
fun test_attach_weapon_succeeds_for_whitelisted_witness() {
    let mut ts = ts::begin(HERO_ADMIN);
    init(ts.ctx());

    ts.next_tx(WEAPON_ADMIN);
    {
        weapon::init_for_testing(ts.ctx());
    };

    ts.next_tx(WEAPON_ADMIN);
    {
        let publisher = ts.take_from_sender<Publisher>();
        let mut allow_list = ts.take_shared<AllowList>();
        weapon::whitelist_witness<HERO_WITNESS>(&publisher, &mut allow_list);
        ts::return_shared(allow_list);
        ts.return_to_sender(publisher);
    };

    ts.next_tx(HERO_ADMIN);
    {
        let admin_cap = ts.take_from_sender<AdminCap>();
        let hero = mint_hero(&admin_cap, b"Hero".to_string(), ts.ctx());
        transfer_hero(&admin_cap, hero, HERO_USER);
        ts.return_to_sender(admin_cap);
    };

    ts.next_tx(HERO_USER);
    {
        let mut treasury = ts.take_shared<Treasury>();
        let hero = ts.take_from_sender<Hero>();
        let weapon_ticket = mint_weapon_ticket(
            coin::mint_for_testing(WEAPON_PRICE, ts.ctx()),
            &mut treasury,
            &hero,
            b"Weapon".to_string(),
            ts.ctx(),
        );
        transfer_weapon_ticket(weapon_ticket, ts.ctx());
        ts.return_to_sender(hero);
        ts::return_shared(treasury);
    };

    ts.next_tx(HERO_USER);
    {
        let allow_list = ts.take_shared<AllowList>();
        let weapon_ticket = ts.take_from_sender<WeaponTicket>();
        let mut hero = ts.take_from_sender<Hero>();
        attach_weapon(&mut hero, weapon_ticket, &allow_list, ts.ctx());
        ts::return_shared(allow_list);
        ts.return_to_sender(hero);
    };

    ts.next_tx(HERO_USER);
    {
        let hero = ts.take_from_sender<Hero>();
        let weapon = dof::borrow<String, Weapon>(&hero.id, b"Weapon".to_string());
        assert_eq!(weapon.name().to_string(), b"Weapon".to_string());
        ts.return_to_sender(hero);
    };

    ts.end();
}
