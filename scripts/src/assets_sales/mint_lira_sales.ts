import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1, keyPair, keyPair2 } from '../helpers.js';
import data from '../../deployed_objects.json';

const keypair =  keyPair();
const keypair1 = keyPair1();
const keypair2 = keyPair2();

const packageId = data.packageId;
const capwrapper = data.lira.CapWrapper;
const rules_package = data.rules.package;

(async () => {
    const txb = new TransactionBlock

    console.log("Mint lira for users")

    const amount1 = txb.moveCall({
        target: `${rules_package}::lira::mint`,
        arguments: [
           txb.object(capwrapper),
           txb.pure(10000000000000),
        ],
    });

    txb.transferObjects([amount1], keypair.getPublicKey().toSuiAddress());

    const amount2 = txb.moveCall({
        target: `${rules_package}::lira::mint`,
        arguments: [
           txb.object(capwrapper),
           txb.pure(10000000000000),
        ],
    });

    txb.transferObjects([amount2], keypair1.getPublicKey().toSuiAddress());

    const amount3 = txb.moveCall({
        target: `${rules_package}::lira::mint`,
        arguments: [
           txb.object(capwrapper),
           txb.pure(10000000000000),
        ],
    });

    txb.transferObjects([amount3], keypair2.getPublicKey().toSuiAddress());

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