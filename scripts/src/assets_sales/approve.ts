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

const keypair = keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const asset1 = data.assets_sales.Asset1;

(async () => {
    const txb = new TransactionBlock
    const user1address: String = "0x863d379fac323bf4caf9b881711a0f41c8ec88db68226ab75287476aa5b4b920"
    console.log("Admin approve asset1")

    txb.moveCall({
        target: `${packageId}::assets_type::approve`,
        arguments: [
            txb.object(admincap),
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(asset1),
            txb.pure(user1address)
        ],
    });

    const {objectChanges}= await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: txb,
        options: {showObjectChanges: true}
    })

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }
    console.log(objectChanges);
})()