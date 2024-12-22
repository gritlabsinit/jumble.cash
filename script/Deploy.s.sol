// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external returns (Raffle raffle, MockERC20 token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy token first
        token = new MockERC20();
        console2.log("TOKEN_ADDRESS=%s", address(token));
        
        // Deploy Raffle contract
        raffle = new Raffle();
        console2.log("RAFFLE_ADDRESS=%s", address(raffle));
        
        vm.stopBroadcast();
        
        return (raffle, token);
    }
} 