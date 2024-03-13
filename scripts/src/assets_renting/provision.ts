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

const keypair1 = keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const contracts = data.assets_renting.Contracts;
const kiosk1 = data.assets_sales.Kiosk1;
const wrapper = data.assets_renting.Wrapper;
const decision: boolean = true;

(async () => {
    const txb = new TransactionBlock

    console.log("Address1 creates Complain")

    txb.moveCall({
        target: `${packageId}::assets_renting::provision`,
        arguments: [
            txb.object(admincap),
            txb.object(contracts),
            txb.object(kiosk1),
            txb.pure(wrapper),
            txb.pure(decision),
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