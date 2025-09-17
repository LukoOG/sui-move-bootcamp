module hot_potato_hero::hero;
use std::string::String;
use std::type_name::{Self, TypeName};
use sui::balance::{Self, Balance};
use sui::coin::Coin;
use sui::sui::SUI;
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};

const EInsufficientWeight: u64 = 0;

const PAYMENT_FEE_BASE: u64 = 1_000_000_000;

public struct PaymentRule {}
public struct WhitelistedRule {}
public struct LevelBonusRule {}
public struct LevelReachedRule {}

public struct LevelUpRequest {
    // TODO: add a property to store the rules
}

public struct LevelUpgradePolicy has key {
    id: UID,
    rules: VecSet<TypeName>,
    min_weight: u8,
    payment_fee: u64,
    whitelist_registry: VecSet<address>,
    treasury: Balance<SUI>,
}

public struct Hero has key {
    id: UID,
    name: String,
    level: u16,
    level_points: u8,
}

fun init(ctx: &mut TxContext) {
    // TODO: Initialize the policy
}

public fun mint_hero(name: String, ctx: &mut TxContext): Hero {
    Hero {
        id: object::new(ctx),
        name,
        level: 1,
        level_points: 0,
    }
}

public fun level_up_request(): LevelUpRequest {
    // TODO: Initialize the request
}

public fun collect_payment_proof(
    request: &mut LevelUpRequest,
    policy: &mut LevelUpgradePolicy,
    coin: Coin<SUI>,
) {
    if (coin.value() >= policy.payment_fee) {
        // TODO: add the payment rule to the request
    };
    policy.treasury.join(coin.into_balance());
}

public fun collect_whitelist_proof(
    request: &mut LevelUpRequest,
    policy: &mut LevelUpgradePolicy,
    ctx: &TxContext,
) {
    if (policy.whitelist_registry.contains(&ctx.sender())) {
        // TODO: add the whitelist rule to the request
    }
}

public fun collect_level_bonus_proof(request: &mut LevelUpRequest, hero: &Hero) {
    if (hero.level_points > 90) {
        // TODO: add the level bonus rule to the request
    }
}

public fun collect_level_reached_proof(request: &mut LevelUpRequest, hero: &Hero) {
    if (hero.level_points >= 100) {
        // TODO: add the level reached rule to the request
    }
}

public fun confirm_level_up(request: LevelUpRequest, policy: &LevelUpgradePolicy, hero: &mut Hero) {
    // TODO: confirm the level up request
}

// Test Only
#[test_only]
use sui::{test_scenario as ts};
#[test_only]
use std::unit_test::assert_eq;
#[test_only]
use sui::coin::Self;

#[test, expected_failure(abort_code = EInsufficientWeight)]
public fun test_cannot_confirm_level_up_request_when_no_proofs_are_atteched() {
    let mut ts = ts::begin(@0xAA);
    {
        init(ts.ctx());
    };

    ts.next_tx(@0xAA);
    {
        let hero = mint_hero(b"hero".to_string(), ts.ctx());
        transfer::transfer(hero, @0xAA);
    };

    ts.next_tx(@0xAA);
    {
        let policy = ts.take_shared<LevelUpgradePolicy>();
        let mut hero = ts.take_from_sender<Hero>();
        let request = level_up_request();

        confirm_level_up(request, &policy, &mut hero)
    };

    abort 1337
}

#[test, expected_failure(abort_code = EInsufficientWeight)]
public fun test_cannot_confirm_level_up_request_when_insufficient_weight() {
    let mut ts = ts::begin(@0xAA);
    {
        init(ts.ctx());
    };

    ts.next_tx(@0xAA);
    {
        let hero = mint_hero(b"hero".to_string(), ts.ctx());
        transfer::transfer(hero, @0xAA);
    };

    ts.next_tx(@0xAA);
    {
        let mut policy = ts.take_shared<LevelUpgradePolicy>();
        let pyament_coin = coin::mint_for_testing(PAYMENT_FEE_BASE, ts.ctx());
        let mut hero = ts.take_from_sender<Hero>();
        let mut request = level_up_request();
        assert_eq!(request.rules.size(), 0);
        collect_payment_proof(&mut request, &mut policy, pyament_coin);
        assert_eq!(request.rules.size(), 1);
        confirm_level_up(request, &policy, &mut hero)
    };

    abort 1337
}

#[test]
public fun test_can_confirm_level_up_request_with_two_single_weighted_proofs() {
    let mut ts = ts::begin(@0xAA);
    {
        init(ts.ctx());
    };

    ts.next_tx(@0xAA);
    {
        let hero = mint_hero(b"hero".to_string(), ts.ctx());
        transfer::transfer(hero, @0xAA);
    };

    ts.next_tx(@0xAA);
    {
        let mut policy = ts.take_shared<LevelUpgradePolicy>();
        let pyament_coin = coin::mint_for_testing(PAYMENT_FEE_BASE, ts.ctx());
        let mut hero = ts.take_from_sender<Hero>();
        let mut request = level_up_request();

        assert_eq!(request.rules.size(), 0);
        collect_payment_proof(&mut request, &mut policy, pyament_coin);
        assert_eq!(request.rules.size(), 1);

        // only accessible in test
        hero.level_points = 91;

        collect_level_bonus_proof(&mut request, &hero);
        assert_eq!(request.rules.size(), 2);

        confirm_level_up(request, &policy, &mut hero);

        assert_eq!(hero.level, 2);
        assert_eq!(hero.level_points, 0);

        ts::return_shared(policy);
        ts.return_to_sender(hero);
    };

    ts.end();
}

#[test]
public fun test_can_confirm_level_up_request_with_one_double_weighted_proof() {
    let mut ts = ts::begin(@0xAA);
    {
        init(ts.ctx());
    };

    ts.next_tx(@0xAA);
    {
        let hero = mint_hero(b"hero".to_string(), ts.ctx());
        transfer::transfer(hero, @0xAA);
    };

    ts.next_tx(@0xAA);
    {
        let policy = ts.take_shared<LevelUpgradePolicy>();
        let mut hero = ts.take_from_sender<Hero>();
        let mut request = level_up_request();

        // only accessible in test
        hero.level_points = 100;

        assert_eq!(request.rules.size(), 0);
        collect_level_reached_proof(&mut request, &hero);
        assert_eq!(request.rules.size(), 1);

        confirm_level_up(request, &policy, &mut hero);

        assert_eq!(hero.level, 2);
        assert_eq!(hero.level_points, 0);

        ts::return_shared(policy);
        ts.return_to_sender(hero);
    };

    ts.end();
}
