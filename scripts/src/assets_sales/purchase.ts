import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair2} from '../helpers.js';
import data from '../../deployed_objects.json';


const keypair = keyPair2();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const kiosk2 = data.assets_sales.Kiosk2;
const policy = data.assets_sales.PolicySale;
const asset1 = data.assets_sales.Asset1;

(async () => {
    const txb = new TransactionBlock
    const  [coin] = txb.splitCoins(txb.gas, ["1000"]);

    console.log("Address2 purchase Asset1")

    txb.moveCall({
        target: `${packageId}::assets_type::purchase`,
        arguments: [
            txb.object(kiosk1),
            txb.object(kiosk2),
            txb.object(ListedTypes),
            txb.object(policy),
            txb.pure(asset1),
            coin
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