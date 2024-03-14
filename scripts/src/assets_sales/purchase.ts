import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair2} from '../helpers.js';
import data from '../../deployed_objects.json';
import { getCoinOfValue } from '@polymedia/suits';

const keypair = keyPair2();

const packageId = data.packageId;
const ListedTypes = data.assets_sales.listedTypes;
const kiosk1 = data.assets_sales.Kiosk1;
const kiosk2 = data.assets_sales.Kiosk2;
const policy = data.assets_sales.PolicySale;
const asset1 = data.assets_sales.Asset1;
const notary = data.lira.NotaryFee;
const cointype= data.lira.liraCoinType;
const owner_address = "0xf903b21b9cdabd89003b25d29c4c2189f44ca0a1cc85f8fe242eb612b0e6be47";

(async () => {
    const txb = new TransactionBlock
    const  [sui] = txb.splitCoins(txb.gas, ["1000"]);
    const [lira] = await getCoinOfValue(client, txb, owner_address, cointype, 1000000001);

    console.log("Address2 purchase Asset1")

    txb.moveCall({
        target: `${packageId}::assets_type::purchase`,
        arguments: [
            txb.object(kiosk1),
            txb.object(kiosk2),
            txb.object(ListedTypes),
            txb.object(notary),
            txb.object(policy),
            txb.pure(asset1),
            sui,
            lira
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