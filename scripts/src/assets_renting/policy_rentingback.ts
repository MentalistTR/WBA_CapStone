import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, find_one_by_type } from '../helpers.js';
import path from "path";
import data from '../../deployed_objects.json';
import fs from 'fs';

const keypair =  keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const publisher = data.assets_sales.Publisher;

const wrapper = `${packageId}::assets::Wrapper`;

(async () => {
    const txb = new TransactionBlock

    console.log("admin creates new policy for rentingback....")

    txb.moveCall({
        target: `${packageId}::assets_type::new_policy`,
        arguments: [
            txb.object(admincap),
            txb.object(publisher),
        ],
        typeArguments: [wrapper]
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

   // Get Policy Share Object 
	const filePath = path.join(__dirname, '../../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const policy = `0x2::transfer_policy::TransferPolicy<${deployed_address.packageId}::assets::Wrapper>`
    //console.log(policy1)

	const policy_id = find_one_by_type(objectChanges, policy)
	if (!policy_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_sales.PolicyRentingBack = policy_id;

    // Get PolicyCap Share Object 
	const PolicyCap = `0x2::transfer_policy::TransferPolicyCap<${deployed_address.packageId}::assets::Wrapper>`

	const policy_cap_id = find_one_by_type(objectChanges, PolicyCap)
	if (!policy_cap_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_sales.PolicyCapRentingBack = policy_cap_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});
})()