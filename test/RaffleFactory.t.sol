// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {RaffleFactory} from "../src/RaffleFactory.sol";
import {BatchRaffle} from "../src/implementations/BatchRaffle.sol";
import {ConstantPricing} from "../src/pricing/ConstantPricing.sol";
import {LogisticPricing} from "../src/pricing/LogisticPricing.sol";

contract RaffleFactoryTest is Test {
    RaffleFactory factory;
    address entropyAddress = address(0x1234);
    address feeCollector = address(0x5678);
    
    function setUp() public {
        entropyAddress = makeAddr("entropy");
        factory = new RaffleFactory(entropyAddress);
    }

    function testDeployConstantPricingRaffle() public {
        address raffle = factory.deployRaffle(
            RaffleFactory.PricingStrategy.CONSTANT,
            feeCollector,
            500 // 5% fee
        );
        assertTrue(raffle != address(0), "Raffle should be deployed");
        assertTrue(address(BatchRaffle(raffle).ticketPricing()) != address(0), "Pricing should be set");
        assertEq(BatchRaffle(raffle).feePercentage(), 500, "Fee should be set");
    }
    function testDeployLogisticPricingRaffle() public {
        address raffle = factory.deployRaffle(
            RaffleFactory.PricingStrategy.LOGISTIC,
            feeCollector,
            500 // 5% fee
        );
        assertTrue(raffle != address(0), "Raffle should be deployed");
        assertTrue(address(BatchRaffle(raffle).ticketPricing()) != address(0), "Pricing should be set");
        assertEq(BatchRaffle(raffle).feePercentage(), 500, "Fee should be set");
    }

    function testFailDeployWithInvalidFee() public {
        factory.deployRaffle(
            RaffleFactory.PricingStrategy.CONSTANT,
            feeCollector,
            1001 // > 10% fee
        );
    }
} 