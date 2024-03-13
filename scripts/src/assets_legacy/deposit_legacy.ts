import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import data from '../../deployed_objects.json';
import fs from 'fs';
import { getCoinOfValue } from '@polymedia/suits';

const keypair1 = keyPair1();

const packageId = data.packageId;
const kiosk = data.assets_sales.Kiosk1;
const coinmeta= data.lira.liraCoinType;

(async () => {
    const txb = new TransactionBlock

    const [coin] = await getCoinOfValue(client, txb, "0x863d379fac323bf4caf9b881711a0f41c8ec88db68226ab75287476aa5b4b920", coinmeta, 10000000000000);

    console.log("Address1 deposit 10000 LIRA")

    txb.moveCall({
        target: `${packageId}::assets_legacy::deposit_legacy`,
        arguments: [
           txb.object(kiosk),
           coin,
           txb.object(coinmeta)
        ],
        typeArguments: [coinmeta]
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