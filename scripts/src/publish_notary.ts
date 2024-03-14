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
        package:"0x23dcee092b89edbe5497cad416c1af2d8fed789c7ff1c7232a4b82b366782d74"
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
      },
      assets_legacy: {
        Legacy: "",
      },
      lira: {
        CapWrapper: "0x0076da9f678fe788c1a117c2108820f7d1f81b3327168449d7db4bd2403d628c",
        liraCoinType: `0x23dcee092b89edbe5497cad416c1af2d8fed789c7ff1c7232a4b82b366782d74::lira::LIRA`,
        OwnerCap: "0xb0f7f90fcea31bb8b599f0d9b73c7549d4e2eac80035d3c27a0eaa903a32d424",
        NotaryFee: "0xb28b6880daeb92374a2265a9a4016cf741c060371039aeb7edd264f5aa09b098",
        coinmetadata: "0xcf8ad062b239462e84b4f4a04a5bb634a70ebb942323c11991a0a6051b2c0248"
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
