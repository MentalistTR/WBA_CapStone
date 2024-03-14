import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair } from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair = keyPair();

const packageId = data.packageId;
const owner_cap = data.lira.OwnerCap;
const notary = data.lira.NotaryFee;
const rule_package = data.rules.package;

(async () => {
    const txb = new TransactionBlock
    console.log("Admin withdraw fees")
 
    txb.moveCall({
        target: `${rule_package}::royalty_rule::withdraw`,
        arguments: [
            txb.object(owner_cap),
            txb.object(notary)
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