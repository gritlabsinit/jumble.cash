#! /bin/bash
source .env && forge script script/Deploy.s.sol:DeployScript --rpc-url ${RPC_URL}  --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}