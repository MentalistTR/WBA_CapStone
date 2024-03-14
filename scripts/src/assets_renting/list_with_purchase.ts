import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair1, find_one_by_type } from '../helpers.js';
import path, { dirname } from "path";

import data from '../../deployed_objects.json';
import fs from 'fs';


const keypair1 = keyPair1();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const contracts = data.assets_renting.Contracts;
const kiosk1 = data.assets_sales.Kiosk1;
const asset2 = data.assets_sales.Asset2;
const wrapper = `${packageId}::assets::Wrapper`;


(async () => {
    const txb = new TransactionBlock
    const user2address: String = "0xf903b21b9cdabd89003b25d29c4c2189f44ca0a1cc85f8fe242eb612b0e6be47"
    console.log("Address1 listing Asset2")

    txb.moveCall({
        target: `${packageId}::assets_renting::list_with_purchase_cap`,
        arguments: [
            txb.object(ListedTypes),
            txb.object(contracts),
            txb.object(kiosk1),
            txb.pure(asset2),
            txb.pure([100]),
            txb.pure(user2address)
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

    // Get PurchaseCap
	const filePath = path.join(__dirname, '../../deployed_objects.json');
    const deployed_address = JSON.parse(fs.readFileSync(filePath, 'utf8'));

	const PurchaseCap = `0x2::kiosk::PurchaseCap<${deployed_address.packageId}::assets::Wrapper>`

	const purchasecap_id = find_one_by_type(objectChanges, PurchaseCap)
	if (!purchasecap_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_renting.PurchaseCap = purchasecap_id;

    
    // Get Wrapper ID
	const Wrapper = `${packageId}::assets::Wrapper`

	const Wrapper_id = find_one_by_type(objectChanges, Wrapper)
	if (!Wrapper_id) {
	    console.log("Error: Could not find Policy")
	    process.exit(1)
	}

	deployed_address.assets_renting.Wrapper = Wrapper_id;

	fs.writeFile(filePath, JSON.stringify(deployed_address, null, 2), 'utf8', (err) => {
		if (err) {
			console.error('false', err);
			return;
		}
		console.log('true');
	});

})()