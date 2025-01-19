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
        
        uint256 raffleId = raffle.raffleCounter();
        uint32 quantity = 5;
        uint256 balanceBefore = token.balanceOf(address(this));
        
        raffle.buyTickets(raffleId, quantity);
        
        uint256 balanceAfter = token.balanceOf(address(this));
        assertTrue(balanceBefore > balanceAfter, "Balance should decrease");
        
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, address(this));
        assertEq(userTickets.length, quantity);
    }
    
    function testSequentialPriceIncrease() public view {        

        uint256 lastPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, 0);
        
        for(uint32 i = 1; i < 10; i++) {
            uint256 currentPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, i);
            assertGe(currentPrice, lastPrice, "Price should never decrease");
            lastPrice = currentPrice;
        }
    }
    
    // function testClaimPrizeByTicketIds() public {
    //     testBuyTicketsWithLogisticPricing(); // Setup and buy tickets
        
    //     // Simulate raffle end and finalization
    //     vm.roll(block.number + 101);
    //     raffle.finalizeRaffle{value: 0.1 ether}(0);
        
    //     uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
    //     uint256 balanceBefore = token.balanceOf(address(this));
        
    //     raffle.claimPrizeByTicketIds(0, userTickets);
        
    //     uint256 balanceAfter = token.balanceOf(address(this));
    //     assertTrue(balanceAfter > balanceBefore, "Prize should be received");
        
    //     // Verify double-claim prevention
    //     vm.expectRevert();
    //     raffle.claimPrizeByTicketIds(0, userTickets);
    // }
    
    // function testFuzzClaimPrizeByTicketIds(
    //     uint32 ticketCount,
    //     uint256 randomSeed,
    //     uint256[] calldata ticketSelection
    // ) public {
    //     vm.assume(ticketCount > 0 && ticketCount <= 50);
    //     vm.assume(ticketSelection.length > 0 && ticketSelection.length <= ticketCount);
        
    //     // Setup raffle with logistic pricing
    //     IndividualRaffle.TicketDistribution[] memory distribution = new IndividualRaffle.TicketDistribution[](1);
    //     distribution[0] = IRaffle.TicketDistribution({
    //         fundPercentage: 100,
    //         ticketQuantity: TOTAL_TICKETS
    //     });
        
    //     raffle.createRaffle(
    //         TOTAL_TICKETS,
    //         address(token),
    //         uint96(BASE_PRICE),
    //         distribution,
    //         100,
    //         50
    //     );
        
    //     // Buy tickets
    //     raffle.buyTickets(0, ticketCount);
        
    //     // Finalize raffle
    //     vm.roll(block.number + 101);
    //     raffle.finalizeRaffle{value: 0.1 ether}(0);
        
    //     // Select tickets to claim
    //     uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
    //     uint256[] memory ticketsToClaim = new uint256[](ticketSelection.length);
    //     for(uint256 i = 0; i < ticketSelection.length; i++) {
    //         ticketsToClaim[i] = userTickets[ticketSelection[i] % userTickets.length];
    //     }
        
    //     uint256 balanceBefore = token.balanceOf(address(this));
    //     raffle.claimPrizeByTicketIds(0, ticketsToClaim);
    //     uint256 balanceAfter = token.balanceOf(address(this));
        
    //     assertGe(balanceAfter, balanceBefore, "Balance should not decrease");
    // }
}