import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { fromB64 } from "@mysten/sui.js/utils";
import dotenv from "dotenv";
import type { SuiObjectChange } from "@mysten/sui.js/client";
import * as fs from "fs";
// import data from '../deployed_objects.json';

dotenv.config();

 // const cointype = data.sui_dollar.SUID_cointype;

export interface IObjectInfo {
    type: string | undefined
	id: string | undefined
}

export const keyPair = () => {
    const privkey = process.env.PRIVATE_KEY
if (!privkey) {
    console.log("Error: DEPLOYER_B64_PRIVKEY not set as env variable.")
    process.exit(1)
}
const keypair = Ed25519Keypair.fromSecretKey(fromB64(privkey).slice(1))
return keypair
}

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });

export const parse_amount = (amount: string) => {
    return parseInt(amount) / 1_000_000_000
}

export const find_one_by_type = (changes: SuiObjectChange[], type: string) => {
    const object_change = changes.find(change => change.type == "created" && change.objectType == type)
    if (object_change?.type == "created") {
        return object_change.objectId
    }
}

export const getId = (type: string): string | undefined => {
    try {
        const rawData = fs.readFileSync('./deployed_objects.json', 'utf8');
        const parsedData: IObjectInfo[] = JSON.parse(rawData);
        const typeToId = new Map(parsedData.map(item => [item.type, item.id]));
        return typeToId.get(type);
    } catch (error) {
        console.error('Error reading the created file:', error);
    }
}

// export const MergeCoin = async (txb:any, amount:string, client:any, sender: string) => {
//     const coins = await client.getCoins({
//       owner: sender,
//       coinType: cointype
//     })
//     console.log(coins.length)

//     const toAppBase = function(obj:any) {
//         return parseFloat(obj) / 1_000000000;
//       };

//     const toContractBase = function(obj:any) {
//         return parseFloat(obj) * 1_000000000;
//     }

//     const collectedCoins = [];
//     const targetAmount = parseInt(amount);
//     let collectedAmount = 0;

//     let i = 0;
//     while(i < coins.data.length && collectedAmount < targetAmount){
//       const temp = coins.data[i];
//       const tempAmount = toAppBase(parseInt(temp.balance));
      
//       if(tempAmount >= targetAmount - collectedAmount){
//         const [splittedCoin] = txb.splitCoins(txb.object(temp.coinObjectId),  [ txb.pure(toContractBase(targetAmount - collectedAmount))]);
//         collectedCoins.push(splittedCoin);
//         collectedAmount += (targetAmount - collectedAmount);
//       }
//       else{
//         const [splittedCoin] = txb.splitCoins(txb.object(temp.coinObjectId), [txb.pure(toContractBase(tempAmount))]);
//         collectedCoins.push(splittedCoin);
//         collectedAmount += tempAmount;
//       }
//       i++;
//     }
//     try{
//       if(collectedCoins.length > 1){
//         txb.mergeCoins(collectedCoins[0], collectedCoins.slice(1));
//       }
//     }
//     catch(e){
//       console.log(e)
//     }
//     return collectedCoins[0];
// }