import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { decodeSuiPrivateKey, encodeSuiPrivateKey } from '@mysten/sui.js/cryptography';
import { fileURLToPath } from "url";
import { writeFileSync } from "fs";
import data from '../../deployed_objects.json';
import fs from 'fs';
import { fromHEX } from "@mysten/bcs";
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';

const keypair1 = keyPair1();

const packageId = data.packageId;
const contracts = data.assets_renting.Contracts;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const kiosk2 = data.assets_sales.Kiosk2;
const policy = data.assets_sales.PolicyRentingBack;
const purch_cap = data.assets_renting.PurchaseCap;
const wrapper = data.assets_renting.Wrapper;


(async () => {
    const txb = new TransactionBlock

    const  [coin] = txb.splitCoins(txb.gas, ["1"]);
 
    console.log("Address1 Get Back Asset2")

    txb.moveCall({
        target: `${packageId}::assets_renting::get_asset`,
        arguments: [
            txb.object(ListedTypes),
            txb.object(contracts),
            txb.object(kiosk1),
            txb.object(kiosk2),
            txb.pure(wrapper),
            txb.object(policy),
            coin,
            txb.object(SUI_CLOCK_OBJECT_ID)
        ],
    });

    const {objectChanges}= await client.signAndExecuteTransactionBlock({
        signer: keypair1,
        transactionBlock: txb,
        options: {showObjectChanges: true}
    })

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }
    console.log(objectChanges);
})()