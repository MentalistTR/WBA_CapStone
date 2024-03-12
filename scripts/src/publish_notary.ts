import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, parse_amount, find_one_by_type } from './helpers.js';
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { writeFileSync } from "fs";


const { execSync } = require('child_process');
const keypair =  keyPair();

const path_to_scripts = dirname(fileURLToPath(import.meta.url))
const path_to_contracts = path.join(path_to_scripts, "../../contracts/asset_operations/sources")

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

// get package id and shareobject in json format 

// get package_id
const package_id = published_change.packageId


export const deployed_address = {
    packageId: published_change.packageId,
    
    rules: {
        package:"0xa282ff0efdf348f951e9b0d9ea7deeb67c1d39055b9fbf630ec1f714d675cb49"
    },

    assets_sales: {
        listedTypes:"",
        AdminCap:"",
        Publisher:"",
        PolicySale: "",
        PolicyRenting: "",
        PolicyRentingBack: "",
        PolicyCapRenting: "",
        PolicyCapRentingBack: "",
        Kiosk1: "",
        Kiosk2: "",
        Asset1: "",
        Asset2: "",
    },
    assets_renting: {
        Contracts: "",
        PurchaseCap : "",
        Wrapper : ""
      }
}

// Get listed_types shareobjects
const listed_types = `${deployed_address.packageId}::assets_type::ListedTypes`

const listed_types_id = find_one_by_type(objectChanges, listed_types)
if (!listed_types_id) {
    console.log("Error: Could not find listed_types object")
    process.exit(1)
}

deployed_address.assets_sales.listedTypes=  listed_types_id;

// Get AdminCap
const adminCap = `${deployed_address.packageId}::assets_type::AdminCap`

const admin_cap_id = find_one_by_type(objectChanges, adminCap)
if (!admin_cap_id) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.assets_sales.AdminCap = admin_cap_id;

// Get publisher
const Publisher = `${deployed_address.packageId}::assets_type::AssetsTypePublisher`

const Publisher_id = find_one_by_type(objectChanges, Publisher)
if (!Publisher_id) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.assets_sales.Publisher = Publisher_id;

// Get Contracts share object 

const Contracts = `${deployed_address.packageId}::assets_renting::Contracts`

const Contracts_id = find_one_by_type(objectChanges, Contracts)

if (!Contracts_id) {
    console.log("Error: Could not find Admin object ")
    process.exit(1)
}

deployed_address.assets_renting.Contracts = Contracts_id;


writeFileSync(path.join(path_to_scripts, "../deployed_objects.json"), JSON.stringify(deployed_address, null, 4))
