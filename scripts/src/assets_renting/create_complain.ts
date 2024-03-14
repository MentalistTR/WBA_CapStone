import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1} from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair1 = keyPair1();

const packageId = data.packageId;
const contracts = data.assets_renting.Contracts;
const kiosk1 = data.assets_sales.Kiosk1;
const wrapper = data.assets_renting.Wrapper;
const reason: String = "alcohol";

(async () => {
    const txb = new TransactionBlock

    console.log("Address1 creates Complain")

    txb.moveCall({
        target: `${packageId}::assets_renting::new_complain`,
        arguments: [
            txb.object(contracts),
            txb.object(kiosk1),
            txb.pure(reason),
            txb.pure(wrapper)
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