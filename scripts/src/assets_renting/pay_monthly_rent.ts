import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair2 } from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair1 = keyPair2();

const packageId = data.packageId;
const kiosk1 = data.assets_sales.Kiosk1;
const asset2 = data.assets_renting.Wrapper;

(async () => {
    const txb = new TransactionBlock
    console.log("Address2 pays monthly rent")
    const  [coin] = txb.splitCoins(txb.gas, ["1000"]);

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