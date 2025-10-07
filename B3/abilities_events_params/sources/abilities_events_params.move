module abilities_events_params::abilities_events_params;
use std::string::String;
use sui::event;

//Error Codes
const EMedalOfHonorNotAvailable: u64 = 111;

// Structs

public struct Hero has key, store {
    id: UID, // required
    name: String,
	medals: vector<Medal>,
}

public struct HeroRegistry has key {
	id: UID,
	heroes: vector<ID>,
}

public struct Medal has key, store{
	id: UID,
	name: String,
}

public struct MedalStorage has key {
	id: UID,
	medals: vector<Medal>,
}

//Events
public struct HeroMinted has copy, drop {
	hero_id: ID,
	owner: address,
}

// Module Initializer
fun init(ctx: &mut TxContext) {
	//define medals
	let medalNames: vector<String> = vector[
		b"Medal of Honor".to_string(), 
		b"Black Knight Honor".to_string(), 
		b"Black Knight Honor".to_string(), 
		b"Medal of Honor".to_string(), 
		b"WWII honor of valor".to_string(),
	];
	
	let mut medalStorage = MedalStorage {
		id: object::new(ctx),
		medals: vector[]
	};
	
	let mut i = 0;
	let lengthMedalNames = medalNames.length();
	
	while(i < lengthMedalNames){
		let medal = Medal {
			id: object::new(ctx),
			name: *vector::borrow(&medalNames, i),
		};
		
		medalStorage.medals.push_back(medal);
		
		i = i + 1;
	};
	
	transfer::share_object(medalStorage);
	
	//define hero regisry
	let heroRegistry = HeroRegistry {
		id: object::new(ctx),
		heroes: vector[],
	};
	
	transfer::share_object(heroRegistry);
	
}

public fun mint_hero(registry: &mut HeroRegistry, name: String, ctx: &mut TxContext): Hero {
    let freshHero = Hero {
        id: object::new(ctx), // creates a new UID
        name,
		medals: vector[]
    };
	
	registry.heroes.push_back(object::id(&freshHero));
	
	let hero_event = HeroMinted {
		hero_id: object::id(&freshHero),
		owner: ctx.sender(),
	};
	
	event::emit(hero_event);
    freshHero
}

#[allow(lint(self_transfer))]
public fun mint_and_keep_hero(registry: &mut HeroRegistry, name: String, ctx: &mut TxContext) {
    let hero = mint_hero(registry, name, ctx);
    transfer::transfer(hero, ctx.sender());
}

fun award_medal(hero: &mut Hero, medal_storage: &mut MedalStorage, medalName: String){
	let medalOption = get_medal(medalName, medal_storage);
	
	//Assert that medal option is not empty -> it hasn't been previously awarded to someone else
	assert!(medalOption.is_some(), EMedalOfHonorNotAvailable);
	
	hero.medals.append(medalOption.to_vec())
}

fun get_medal(name: String, medalStorage: &mut MedalStorage): option::Option<Medal>{
	let mut i: u64 = 0;
	let length = medalStorage.medals.length();
	
	while(i < length){
		if(medalStorage.medals[i].name == name){
			let extractedMedal = vector::remove(&mut medalStorage.medals, i);
			return option::some(extractedMedal)
		};
		i = i + 1;
	};
	
	option::none<Medal>()
}

public fun award_medal_of_custom(hero: &mut Hero, medal_storage: &mut MedalStorage, medalName: String){
	award_medal(hero, medal_storage, medalName)
}

public fun award_medal_of_cross(hero: &mut Hero, medal_storage: &mut MedalStorage){
	award_medal(hero, medal_storage, b"Air Force Cross".to_string())
}

public fun award_medal_of_honor(hero: &mut Hero, medal_storage: &mut MedalStorage){
	award_medal(hero, medal_storage, b"Black Knight Honor".to_string())
}

public fun award_medal_of_valor(hero: &mut Hero, medal_storage: &mut MedalStorage){
	award_medal(hero, medal_storage, b"WWII honor of valor".to_string())
}

/////// Tests ///////

#[test_only]
use sui::test_scenario as ts;
//#[test_only]
//use sui::test_scenario::{take_shared, return_shared};
#[test_only]
use sui::test_utils::{destroy};
#[test_only]
use std::unit_test::assert_eq;

//--------------------------------------------------------------
//  Test 1: Hero Creation
//--------------------------------------------------------------
//  Objective: Verify the correct creation of a Hero object.
//  Tasks:
//      1. Complete the test by calling the `mint_hero` function with a hero name.
//      2. Assert that the created Hero's name matches the provided name.
//      3. Properly clean up the created Hero object using `destroy`.
//--------------------------------------------------------------
#[test]
fun test_hero_creation() {
    let mut test = ts::begin(@USER);
    init(test.ctx());
    test.next_tx(@USER);

    //Get hero Registry
	let mut test_registry = HeroRegistry{
		id: object::new(test.ctx()),
		heroes: vector[],
	};
	test.next_tx(@USER);

    let hero = mint_hero(&mut test_registry, b"Flash".to_string(), test.ctx());
    assert_eq!(hero.name, b"Flash".to_string());

    destroy(hero);
	destroy(test_registry);
    test.end();
}

//--------------------------------------------------------------
//  Test 2: Event Emission
//--------------------------------------------------------------
//  Objective: Implement event emission during hero creation and verify its correctness.
//  Tasks:
//      1. Define a `HeroMinted` event struct with appropriate fields (e.g., hero ID, owner address).  Remember to add `copy, drop` abilities!
//      2. Emit the `HeroMinted` event within the `mint_hero` function after creating the Hero.
//      3. In this test, capture emitted events using `event::events_by_type<HeroMinted>()`.
//      4. Assert that the number of emitted `HeroMinted` events is 1.
//      5. Assert that the `owner` field of the emitted event matches the expected address (e.g., @USER).
//--------------------------------------------------------------
#[test]
fun test_event_thrown() { assert_eq!(1, 1); }

//--------------------------------------------------------------
//  Test 3: Medal Awarding
//--------------------------------------------------------------
//  Objective: Implement medal awarding functionality to heroes and verify its effects.
//  Tasks:
//      1. Define a `Medal` struct with appropriate fields (e.g., medal ID, medal name). Remember to add `key, store` abilities!
//      2. Add a `medals: vector<Medal>` field to the `Hero` struct to store the medals a hero has earned.
//      3. Create functions to award medals to heroes, e.g., `award_medal_of_honor(hero: &mut Hero)`.
//      4. In this test, mint a hero.
//      5. Award a specific medal (e.g., Medal of Honor) to the hero using your `award_medal_of_honor` function.
//      6. Assert that the hero's `medals` vector now contains the awarded medal.
//      7. Consider creating a shared `MedalStorage` object to manage the available medals.
//--------------------------------------------------------------
#[test]
fun test_medal_award() { assert_eq!(1, 1); }
