import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair2} from '../helpers.js';
import data from '../../deployed_objects.json';
import {SUI_CLOCK_OBJECT_ID} from '@mysten/sui.js/utils';
import { getCoinOfValue } from '@polymedia/suits';

const keypair1 = keyPair2();

const packageId = data.packageId;
const contracts = data.assets_renting.Contracts;
const ListedTypes = data.assets_sales.listedTypes;
const notary = data.lira.NotaryFee;
const kiosk1 = data.assets_sales.Kiosk1;
const kiosk2 = data.assets_sales.Kiosk2;
const policy = data.assets_sales.PolicyRenting;
const purch_cap = data.assets_renting.PurchaseCap;
const wrapper = data.assets_renting.Wrapper;
const cointype= data.lira.liraCoinType;
const owner_address = "0xf903b21b9cdabd89003b25d29c4c2189f44ca0a1cc85f8fe242eb612b0e6be47";

(async () => {
    const txb = new TransactionBlock
    const  [sui] = txb.splitCoins(txb.gas, ["1000"]);
    const [lira] = await getCoinOfValue(client, txb, owner_address, cointype, 1000000001);  
    const rental = 6;

    console.log("Address2 Renting Asset2")

    txb.moveCall({
        target: `${packageId}::assets_renting::rent`,
        arguments: [
            txb.object(contracts),
            txb.object(ListedTypes),
            txb.object(notary),
            txb.object(kiosk1),
            txb.object(kiosk2),
            txb.object(policy),
            txb.object(purch_cap),
            txb.pure(wrapper),
            sui,
            lira,
            txb.pure(rental),
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
})()