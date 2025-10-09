import { Button } from "@radix-ui/themes";
import { 
		useCurrentAccount, 
		useSignAndExecuteTransaction, 
		useSuiClient 
	} from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { useState, useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

export function MintNFTForm(){
	//const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();
	//using the async variant
	const { mutateAsync: signAndExecuteTransaction } = useSignAndExecuteTransaction();
	const [digest, setDigest] = useState('');
	const account = useCurrentAccount();
	const suiClient = useSuiClient();
	const queryClient = useQueryClient();
	
	const handleMint = () => {
		if(!account){
			alert("Please connect your wallet first.")
			return 
		}
		//alert("Minting not yet implemented")
		const tx = new Transaction()
		const hero = tx.moveCall({
			target: "0xc413c2e2c1ac0630f532941be972109eae5d6734e540f20109d75a59a1efea1e::hero::mint_hero",
			arguments: [],
			typeArguments: []
		})
		console.log(account.address);
		tx.transferObjects([hero], account.address);
		/*
		signAndExecuteTransaction(
			{
				transaction: tx,
			},
			{
				onSuccess: ({ digest }) => {
					console.log('executed transaction', digest);
					alert('NFT minted successfully: ', digest);
					setDigest(digest);
				}
			}
		)
		*/
		signAndExecuteTransaction({
			transaction: tx
		}).then(async ({ digest })=>{
			await suiClient.waitForTransaction({digest: digest});
			
			console.log(digest);
			alert('NFT minted successfully: ', digest);
			setDigest(digest);
			
			queryClient.invalidate({
				predicate: (query) => 
					query.queryKey[0] === "testnet" &&
					query.queryKey[1] === "getOwnedObjects",
			})
		})
		.catch((error)=>{ console.error("Transaction error: ", error); alert("Transaction failed") })
		
	}
	
	useEffect(()=>{
		console.log(digest)
	}, [digest])
	
	return(
		<Button onClick={handleMint}>Mint NFT</Button>
	)
}