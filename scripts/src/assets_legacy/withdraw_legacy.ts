import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair } from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair = keyPair();

const packageId = data.packageId;
const legacy = data.assets_legacy.Legacy;
const cointype= data.lira.liraCoinType;

(async () => {
    const txb = new TransactionBlock
    const name: String = "Tr Lira"
    console.log("Heir Withdraw funds")

    let amount1 =  txb.moveCall({
        target: `${packageId}::assets_legacy::withdraw`,
        arguments: [
           txb.object(legacy),
           txb.pure(name)
        ],
        typeArguments: [cointype]
    });

    txb.transferObjects([amount1], keypair.getPublicKey().toSuiAddress());

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