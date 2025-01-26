#! /bin/bash
mkdir -p abi
mkdir -p abi-ts

python3 script/generate_abi.py

echo "export const RaffleABI = $(cat abi/BatchRaffle.json)" > abi-ts/Raffle.ts                      
echo "export const ERC20ABI = $(cat abi/MockERC20.json)" > abi-ts/ERC20.ts