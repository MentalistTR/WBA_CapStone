import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { writeFileSync } from "fs";
import data from '../../deployed_objects.json';

const keypair =  keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const listedTypes = data.assets_sales.listedTypes;

(async () => {
    const txb = new TransactionBlock

    console.log("admin creates new type....")

    let type1: String = "House";
    let type2: String = "Car";
    let type3: String = "Land";
    let type4: String = "Shop";

    txb.moveCall({
        target: `${packageId}::assets_type::create_type`,
        arguments: [
            txb.object(admincap),
            txb.object(listedTypes),
            txb.pure(type1)
        ]
    });

    txb.moveCall({
        target: `${packageId}::assets_type::create_type`,
        arguments: [
            txb.object(admincap),
            txb.object(listedTypes),
            txb.pure(type2)
        ]
    });

    txb.moveCall({
        target: `${packageId}::assets_type::create_type`,
        arguments: [
            txb.object(admincap),
            txb.object(listedTypes),
            txb.pure(type3)
        ]
    });

    txb.moveCall({
        target: `${packageId}::assets_type::create_type`,
        arguments: [
            txb.object(admincap),
            txb.object(listedTypes),
            txb.pure(type4)
        ]
    });

    const {objectChanges}= await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: txb,
        options: {showObjectChanges: true}
    })

    console.log(objectChanges);
})()