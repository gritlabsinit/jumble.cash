// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {IndividualRaffle} from "../../src/implementations/IndividualRaffle.sol";
import {IRaffle} from "../../src/interfaces/IRaffle.sol";
import {LogisticPricing} from "../../src/pricing/LogisticPricing.sol";
import {MockERC20} from "../MockERC20.sol";
import {MockEntropy} from "../MockEntropy.sol";

contract IndividualRaffleTest is Test {
    IndividualRaffle raffle;
    MockERC20 token;
    MockEntropy entropy;
    LogisticPricing pricing;
    
    address feeCollector = address(0x123);
    uint256 constant FEE_PERCENTAGE = 500; // 5%
    uint256 constant BASE_PRICE = 100e6; // 100 USDC
    uint32 constant TOTAL_TICKETS = 100;
    
    function setUp() public {
        token = new MockERC20();
        entropy = new MockEntropy();
        pricing = new LogisticPricing();
        
        raffle = new IndividualRaffle(
            address(entropy),
            address(pricing),
            feeCollector,
            FEE_PERCENTAGE
        );
        
        token.mint(address(this), 1000000e6);
        token.approve(address(raffle), type(uint256).max);
    }
    
    function testBuyTicketsWithLogisticPricing() public {
        // Create raffle first
        IndividualRaffle.TicketDistribution[] memory distribution = new IndividualRaffle.TicketDistribution[](1);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 100,
            ticketQuantity: TOTAL_TICKETS
        });
        
        raffle.createRaffle(
            TOTAL_TICKETS,
            address(token),
            uint96(BASE_PRICE),
            distribution,
            100,
            50
        );
        
        uint32 quantity = 5;
        uint256 balanceBefore = token.balanceOf(address(this));
        
        raffle.buyTickets(0, quantity);
        
        uint256 balanceAfter = token.balanceOf(address(this));
        assertTrue(balanceBefore > balanceAfter, "Balance should decrease");
        
        uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
        assertEq(userTickets.length, quantity);
    }
    
    function testSequentialPriceIncrease() public {
        testBuyTicketsWithLogisticPricing();
        
        uint256 lastPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, 0);
        
        for(uint32 i = 1; i < 10; i++) {
            uint256 currentPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, i);
            assertGe(currentPrice, lastPrice, "Price should never decrease");
            lastPrice = currentPrice;
        }
    }
}