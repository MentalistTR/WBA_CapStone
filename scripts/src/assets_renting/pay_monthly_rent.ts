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

const keypair1 = keyPair2();

const packageId = data.packageId;
const kiosk1 = data.assets_sales.Kiosk1;
const asset2 = data.assets_renting.Wrapper;

(async () => {
    const txb = new TransactionBlock
    console.log("Address2 pays monthly rent")
    const  [coin] = txb.splitCoins(txb.gas, ["100"]);

    txb.moveCall({
        target: `${packageId}::assets_renting::pay_monthly_rent`,
        arguments: [
            txb.object(kiosk1),
            coin,
            txb.pure(asset2)
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