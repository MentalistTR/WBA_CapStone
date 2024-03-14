import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair} from '../helpers.js';
import data from '../../deployed_objects.json';


const keypair = keyPair();

const packageId = data.packageId;
const admincap = data.assets_sales.AdminCap;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const kiosk2 = data.assets_sales.Kiosk2;
const asset1 = data.assets_sales.Asset1;
const asset2 = data.assets_sales.Asset2;


(async () => {
    const txb = new TransactionBlock
    const user1address: String = "0x863d379fac323bf4caf9b881711a0f41c8ec88db68226ab75287476aa5b4b920"
    const user2address: String = "0xf903b21b9cdabd89003b25d29c4c2189f44ca0a1cc85f8fe242eb612b0e6be47"

    console.log("Admin approve asset1")

    txb.moveCall({
        target: `${packageId}::assets_type::approve`,
        arguments: [
            txb.object(admincap),
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(asset1),
            txb.pure(user1address)
        ],
    });
    console.log("Admin approve asset2")

    txb.moveCall({
        target: `${packageId}::assets_type::approve`,
        arguments: [
            txb.object(admincap),
            txb.object(ListedTypes),
            txb.object(kiosk1),
            txb.pure(asset2),
            txb.pure(user1address)
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