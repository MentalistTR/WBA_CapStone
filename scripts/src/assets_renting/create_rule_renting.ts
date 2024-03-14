import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair} from '../helpers.js';

import data from '../../deployed_objects.json';


const keypair1 = keyPair();

const packageId = data.packageId;
const policy = data.assets_sales.PolicyRenting;
const policy_cap = data.assets_sales.PolicyCapRenting;
const rules_package = data.rules.package;
const wrapper = `${packageId}::assets::Wrapper`;

(async () => {
    const txb = new TransactionBlock

    console.log("Admin adds loan_duration rule for renting operations")
    const min = 6;
    const max = 12;

    txb.moveCall({
        target: `${rules_package}::loan_duration::add`,
        arguments: [
            txb.object(policy),
            txb.object(policy_cap),
            txb.pure(min),
            txb.pure(max)
        ],
        typeArguments: [wrapper]
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