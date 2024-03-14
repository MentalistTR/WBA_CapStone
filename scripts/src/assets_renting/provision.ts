import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair } from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair1 = keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const contracts = data.assets_renting.Contracts;
const kiosk1 = data.assets_sales.Kiosk1;
const wrapper = data.assets_renting.Wrapper;
const decision: boolean = true;

(async () => {
    const txb = new TransactionBlock

    console.log("Admin make provision")

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