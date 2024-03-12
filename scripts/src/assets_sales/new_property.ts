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

const keypair1 = keyPair1();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const asset1 = data.assets_sales.Asset1;

(async () => {
    const txb = new TransactionBlock

    const type: String = "Area";
    const definition: String = "144m2";
    console.log("Address1 creates property for asset")

    txb.moveCall({
        target: `${packageId}::assets_type::new_property`,
        arguments: [
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(asset1),
            txb.pure(type),
            txb.pure(definition)
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