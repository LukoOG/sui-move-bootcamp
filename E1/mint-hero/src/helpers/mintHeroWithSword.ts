import { SuiTransactionBlockResponse } from "@mysten/sui/client";
import { Transaction } from "@mysten/sui/transactions"
import { ENV } from "../env"
import { getSigner } from "./getSigner"
import { getAddress } from "./getAddress"
import { suiClient } from "../suiClient"

/**
 * Builds, signs, and executes a transaction for:
 * * minting a Hero NFT: use the `package_id::hero::mint_hero` function
 * * minting a Sword NFT: use the `package_id::blacksmith::new_sword` function
 * * attaching the Sword to the Hero: use the `package_id::hero::equip_sword` function
 * * transferring the Hero to the signer
 */
export const mintHeroWithSword =
  async (): Promise<SuiTransactionBlockResponse> => {
    
	const tx = new Transaction()
	
	//1. mint Hero
	const Hero = tx.moveCall({
		target: `${ENV.PACKAGE_ID}::hero::mint_hero`,
		arguments: [],
		typeArguments: [],
	})
	//2. mint sword
	const Sword = tx.moveCall({
		target: `${ENV.PACKAGE_ID}::blacksmith::new_sword`,
		arguments: [ tx.pure.u64(120) ],
		typeArguments: [],
	})
	//3. Attaching the sword to the Hero
	tx.moveCall({
		target: `${ENV.PACKAGE_ID}::hero::equip_sword`,
		arguments: [ Hero, Sword ],
		typeArguments: [
			`${ENV.PACKAGE_ID}::hero::Hero`, 
			`${ENV.PACKAGE_ID}::blacksmith::Sword`
		],
	})
	tx.transferObjects([Hero], getAddress({ secretKey: ENV.USER_SECRET_KEY }));
	tx.setGasPrice(5000);
	const response  = suiClient.signAndExecuteTransaction({
		transaction: tx,
		signer: getSigner({ secretKey: ENV.USER_SECRET_KEY }),
		options: {
			showEffects: true,
			showObjectChanges: true,
		}
	})
    return response;
  };
