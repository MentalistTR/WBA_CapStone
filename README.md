# Legacy - Decentralized Legacy Module

## Introduction
Legacy is a module that enables individuals to distribute their token assets to designated persons and percentages at a specific time in the future.

## Features
- The new_legacy function allows users to create a legacy share object. When creating their legacy, users need only enter when it will be distributed. Other parameters will be default.
- The deposit_legacy function allows legacy owners to deposit any token into their legacy. These deposited tokens are stored within a bag as <string, vector<string>>.
- The new_heirs function allows legacy owners to enter heirs and their percentages. The total of the percentages must equal 100, and at least one address must be entered.
- The distribute function can only be called by one of the heirs. After the time for the legacy has arrived, the heirs can call this function to have the shares stored in the heirs_amount bag distributed to them according to their percentages.
- The withdraw function allows heirs to withdraw a specific coin after the legacy has been distributed.

  ## How to Use
  Within the src/helpers.ts file of the script file, there are three key pairs: keyPair, keyPair1, and keyPair2. The private keys for keyPair1 and keyPair2 are already entered, so you don't need to modify them. However, you need to enter your own 
  private key for keyPair. To do this, you should create a file named .env within the scripts folder and paste your private key into the designated spot.

  ![Ekran Görüntüsü (918)](https://github.com/MentalistTR/dacade-legacy/assets/100069341/e5e9c83a-1d44-4392-85c2-ae0591a37648)

## To build
```bash
sui move build
````
## To Local Test 
 ```bash
sui move test
````
## To setup bun 
 ```bash
bun init
````
## To publish
 ```bash
bun run publish_legacy
````
## To Create Legacy
 ```bash
bun run create_legacy
````
## To Set Heirs
 ```bash
bun run set_heirs
````
## To Mint usdc
 ```bash
bun run mint_usdc
````
## To Mint usdt
 ```bash
bun run mint_usdt
````
## To Local Test 
 ```bash
bun run set_heirs
````
## To Deposit Legacy usdc
 ```bash
bun run deposit_usdc_legacy
````
## To Deposit Legacy usdt
 ```bash
bun run deposit_usdt_legacy
````
## To distribute_legacy
 ```bash
bun run distribute_legacy
````
## To withdraw_legacy
 ```bash
bun run withdraw_legacy
````
## To run all scripts
 ```bash
bun run run_legacy
````
 
