# Notary - Centralized Notary System

## Introduction
Notary allows people to verify their real-world assets within the system of a nation-state and then use sales and renting operations. Additionally, by locking their funds, they can leave an heris to whomever they wish.

## Features
 ### Assets Sales Module
 - Users must first create their own kiosks. All transactions will take place in the kiosk.
 - Admins can create asset types. You can think of them like enums.
 - Different transfer policies for Sales and Renting are created here.
 - The user creates their asset and waits for the admin to approve it. An approved asset can be used for sales and renting, but Houses and Shops can only be used for renting.
 - The user can add or remove new properties as descriptions to their asset.
 - Users can list their assets with a list. They can purchase with Purchase, and if a sales operation occurs, they can withdraw their funds.

  ### Assets Renting Module
  - In this module, we will store purchase capabilities in the Contracts share object in storage because the protocol must decide in case of a dispute between the leaser and the owner.
  - For this module, we have two transfer policies: one for renting and the other for get_asset. Both have different rules, and you can look at these rules in the rules package.
  - The user must make their monthly payment with the pay_monthly_rent function before one month is up; otherwise, the owner can call the get_asset function.
  - With the new_complain method, either the leaser or the owner can file a complaint. The protocol decides who will make the decision, and the one who is found to be right is transferred a one-month deposit fee.
  ### Assets Legacy Module
  - In this module, users can store their funds in the bonds at their kiosk. When the time comes, and one of the heirs distributes the legacy, the funds from the user's kiosk are distributed to previously determined addresses and percentages.

  ## How to Use
  The necessary explanations have been provided in the module and above. Scripts have been written to prove that each function works. Currently, local testing is operational. For the renting script process, you need to uncomment a parameter in the module below.


## To build
```bash
sui move build
````
## To Test
 ```bash
sui move test
````
## To setup bun
 ```bash
cd scripts
````
 ```bash
bun init
````
## To publish and test all assets_sales
 ```bash
bun run publish_notary
````
## To run renting scripts, go to contracts/asset_operations/assets_renting module and we must uncomment line 177
https://hizliresim.com/7w4oq0v

## After the changes are completed, it should be as follows on the right.

https://hizliresim.com/1o6zxtx

