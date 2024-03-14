import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1, find_one_by_type } from '../helpers.js';
import path from "path";
import data from '../../deployed_objects.json';
import fs from 'fs';

import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';

const keypair1 = keyPair1();

const packageId = data.packageId;

(async () => {
    const txb = new TransactionBlock
    const remaining = 5;
    console.log("Address1 creates Legacy")

    txb.moveCall({
        target: `${packageId}::assets_legacy::new_legacy`,
        arguments: [
           txb.pure(remaining),
           txb.object(SUI_CLOCK_OBJECT_ID)
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

    // Get Legacy share id 
	const filePath = path.join(__dirname, '../../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const Legacy = `${deployed_address.packageId}::assets_legacy::Legacy`

	const legacy_id = find_one_by_type(objectChanges, Legacy)
	if (!legacy_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_legacy.Legacy = legacy_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});

})()