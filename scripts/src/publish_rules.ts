import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, parse_amount, find_one_by_type } from './helpers.js';
import path, { dirname } from "path";
import { fileURLToPath } from "url";

const { execSync } = require('child_process');
const keypair =  keyPair();

const path_to_scripts = dirname(fileURLToPath(import.meta.url))

const path_to_contracts = path.join(path_to_scripts, "../../contracts/rules/sources")

console.log("Building move code...")

const { modules, dependencies } = JSON.parse(execSync(
    `sui move build --dump-bytecode-as-base64 --path ${path_to_contracts}`,
    { encoding: "utf-8" }
))

console.log("Deploying contracts...");
console.log(`Deploying from ${keypair.toSuiAddress()}`)

const tx = new TransactionBlock();

const [upgradeCap] = tx.publish({
	modules,
	dependencies,
});

tx.transferObjects([upgradeCap], keypair.getPublicKey().toSuiAddress());

const { objectChanges, balanceChanges } = await client.signAndExecuteTransactionBlock({
    signer: keypair, transactionBlock: tx, options: {
        showBalanceChanges: true,
        showEffects: true,
        showEvents: true,
        showInput: false,
        showObjectChanges: true,
        showRawInput: false
    }
})

if (!balanceChanges) {
    console.log("Error: Balance Changes was undefined")
    process.exit(1)
}
if (!objectChanges) {
    console.log("Error: object  Changes was undefined")
    process.exit(1)
}

console.log(objectChanges)
console.log(`Spent ${Math.abs(parse_amount(balanceChanges[0].amount))} on deploy`);

const published_change = objectChanges.find(change => change.type == "published")
if (published_change?.type !== "published") {
    console.log("Error: Did not find correct published change")
    process.exit(1)
}

// get package_id
// const package_id = published_change.packageId

// export const deployed_address: any = {
//     packageId: published_change.packageId,
// }

// writeFileSync(path.join(path_to_scripts, "../deployed_objects.json"), JSON.stringify(deployed_address, null, 4))
