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
const capwrapper = data.lira.CapWrapper;

(async () => {
    const txb = new TransactionBlock

    console.log("Address1 mints lira")

    const amount = txb.moveCall({
        target: `${packageId}::lira::mint`,
        arguments: [
           txb.object(capwrapper),
           txb.pure(10000000000000),
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