import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import data from '../../deployed_objects.json';
import fs from 'fs';

const keypair1 = keyPair1();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;

(async () => {
    const txb = new TransactionBlock
    const type: String = "House";
    console.log("Address1 creates asset1 for sales")

    txb.moveCall({
        target: `${packageId}::assets_type::create_asset`,
        arguments: [
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(type)
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

    // Get Asset1
	const filePath = path.join(__dirname, '../../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const Asset1 = `${deployed_address.packageId}::assets::Asset`

	const Asset1_id = find_one_by_type(objectChanges, Asset1)
	if (!Asset1_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_sales.Asset1 = Asset1_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});
})()