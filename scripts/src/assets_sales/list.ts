import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1} from '../helpers.js';
import data from '../../deployed_objects.json';


const keypair1 = keyPair1();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const asset1 = data.assets_sales.Asset1;

(async () => {
    const txb = new TransactionBlock
    const coin = 1000;
    console.log("Address1 listing Asset1")

    txb.moveCall({
        target: `${packageId}::assets_type::list`,
        arguments: [
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(asset1),
            txb.pure(coin)
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