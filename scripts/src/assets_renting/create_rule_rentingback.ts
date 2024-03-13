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
const policy = data.assets_sales.PolicyRentingBack;
const policy_cap = data.assets_sales.PolicyCapRentingBack;
const rules_package = data.rules.package;
const wrapper = `${packageId}::assets::Wrapper`;

(async () => {
    const txb = new TransactionBlock

    console.log("Admin adds time_duration rule for renting operations")
    txb.moveCall({
        target: `${rules_package}::time_duration::add`,
        arguments: [
            txb.object(policy),
            txb.object(policy_cap),
        ],
        typeArguments: [wrapper]
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