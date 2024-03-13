import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, keyPair1, keyPair2, parse_amount, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';

const keypair1 = keyPair();

const packageId = data.packageId;
const kiosk = data.assets_sales.Kiosk1;
const legacy = data.assets_legacy.Legacy;
const cointype= data.lira.liraCoinType;
const admin_cap = data.assets_sales.AdminCap;

(async () => {
    const txb = new TransactionBlock

    console.log("Admin distribute funds")

    txb.moveCall({
        target: `${packageId}::assets_legacy::distribute`,
        arguments: [
           txb.object(admin_cap),
           txb.object(legacy),
           txb.object(kiosk),
           txb.object(SUI_CLOCK_OBJECT_ID)
        ],
        typeArguments: [cointype]
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