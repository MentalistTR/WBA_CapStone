import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { writeFileSync } from "fs";
import data from '../../deployed_objects.json';
import fs from 'fs';

const keypair =  keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const publisher = data.assets_sales.Publisher;

const asset = `${packageId}::assets::Asset`;
const wrapper = `${packageId}::assets::Wrapper`;

(async () => {
    const txb = new TransactionBlock

    console.log("admin creates new type....")

    txb.moveCall({
        target: `${packageId}::assets_type::new_policy`,
        arguments: [
            txb.object(admincap),
            txb.object(publisher),
        ],
        typeArguments: [asset]
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

	const policy1 = `0x2::transfer_policy::TransferPolicy<${deployed_address.packageId}::assets::Asset>`
    //console.log(policy1)

	const policy1_id = find_one_by_type(objectChanges, policy1)
	if (!policy1_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_sales.PolicySale = policy1_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});
})()