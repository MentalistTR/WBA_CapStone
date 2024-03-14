import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";
import data from '../../deployed_objects.json';
import fs from 'fs';

const keypair1 = keyPair1();
const keypair2 = keyPair2();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;

(async () => {
    const txb = new TransactionBlock

    console.log("Address2 creates his kiosk")

    txb.moveCall({
        target: `${packageId}::assets_type::create_kiosk`,
        arguments: [
            txb.object(ListedTypes),
        ],
    });

    const {objectChanges}= await client.signAndExecuteTransactionBlock({
        signer: keypair2,
        transactionBlock: txb,
        options: {showObjectChanges: true}
    })

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }

    console.log(objectChanges);

    // Get Kiosk1 share object  
	const filePath = path.join(__dirname, '../../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const kiosk1 = `0x2::kiosk::Kiosk`

	const kiosk1_id = find_one_by_type(objectChanges, kiosk1)
	if (!kiosk1_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_sales.Kiosk2 = kiosk1_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});
})()