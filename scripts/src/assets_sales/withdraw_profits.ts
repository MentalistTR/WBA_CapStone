import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';


const keypair = keyPair1();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;

(async () => {
    const txb = new TransactionBlock
    console.log("Address1 withdraw_profits")

    const [withdraw] = txb.moveCall({
        target: `${packageId}::assets_type::withdraw_profits`,
        arguments: [
            txb.object(kiosk1),
            txb.object(ListedTypes),
            txb.pure([1000])
        ],
    });

    txb.transferObjects([withdraw], keypair.getPublicKey().toSuiAddress());

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