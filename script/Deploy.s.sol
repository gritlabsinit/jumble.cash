// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external returns (Raffle raffle, MockERC20 token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address entropyAddress = vm.envAddress("ENTROPY_ADDRESS");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");
        uint256 feePercentage = vm.envUint("FEE_PERCENTAGE");

        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy token first
        token = new MockERC20();
        console2.log("TOKEN_ADDRESS=%s", address(token));
        
        // Deploy Raffle contract
        raffle = new Raffle(entropyAddress, feeCollector, feePercentage);
        console2.log("RAFFLE_ADDRESS=%s", address(raffle));
        
        vm.stopBroadcast();
        
        return (raffle, token);
    }
} 