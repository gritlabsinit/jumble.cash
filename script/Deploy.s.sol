// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/RaffleFactory.sol";
import "../src/pricing/ConstantPricing.sol";
import "../src/pricing/LogisticPricing.sol";
import "../test/MockERC20.sol";

contract DeployScript is Script {
    function run() public returns (address raffle, MockERC20 token) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address entropyAddress = vm.envAddress("ENTROPY_ADDRESS");
        address feeCollector = vm.envAddress("FEE_COLLECTOR");
        uint256 feePercentage = vm.envUint("FEE_PERCENTAGE");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy token first
        token = new MockERC20();
    
        // Deploy RaffleFactory
        RaffleFactory factory = new RaffleFactory(entropyAddress);
        console.log("RaffleFactory deployed to:", address(factory));

        // Deploy initial raffles with different pricing strategies
        address constantRaffle = factory.deployRaffle(
            RaffleFactory.PricingStrategy.CONSTANT,
            feeCollector,
            feePercentage
        );
        console.log("Constant Pricing Raffle deployed to:", constantRaffle);

        address logisticRaffle = factory.deployRaffle(
            RaffleFactory.PricingStrategy.LOGISTIC,
            feeCollector,
            feePercentage
        );
        console.log("Logistic Pricing Raffle deployed to:", logisticRaffle);

        vm.stopBroadcast();

        // Log deployment information
        console.log("\nDeployment Summary:");
        console.log("------------------");

        console.log("Entropy Address:", entropyAddress);
        console.log("Fee Collector:", feeCollector);
        console.log("Fee Percentage:", feePercentage);
        console.log("Factory:", address(factory));
        console.log("Constant Raffle:", constantRaffle);
        console.log("Logistic Raffle:", logisticRaffle);
        console2.log("TOKEN_ADDRESS=%s", address(token));
        console2.log("RAFFLE_ADDRESS=%s", constantRaffle);

        return (constantRaffle, token);
    }
} 