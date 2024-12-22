#! /bin/bash

# Generate the ABI for the Raffle contract  
forge inspect Raffle abi > abi/Raffle.json

# Generate the ABI for the MockERC20 contract
forge inspect src/MockERC20.sol:MockERC20 abi > abi/MockERC20.json

echo "export const RaffleABI = $(cat abi/Raffle.json)" > src/abi/Raffle.ts                      
echo "export const ERC20ABI = $(cat abi/MockERC20.json)" > src/abi/ERC20.ts