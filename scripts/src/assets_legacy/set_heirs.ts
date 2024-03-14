import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1} from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair1 = keyPair1();

const packageId = data.packageId;
const legacy = data.assets_legacy.Legacy;
const heir1: String = "0x7ea139cbf7c44b8477d56d087f4475fe599e492958bf1175bb54aedd9fc99d8e";
const heir2: String = "0xf903b21b9cdabd89003b25d29c4c2189f44ca0a1cc85f8fe242eb612b0e6be47";

(async () => {
    const txb = new TransactionBlock
    const heirs = [heir1, heir2];

    console.log("Address1 set heirs")

    txb.moveCall({
        target: `${packageId}::assets_legacy::new_heirs`,
        arguments: [
           txb.object(legacy),
           txb.pure(heirs),
           txb.pure([5000,5000]) 
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