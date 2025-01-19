// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {BatchRaffle} from "../../src/implementations/BatchRaffle.sol";
import {IRaffle} from "../../src/interfaces/IRaffle.sol";
import {ConstantPricing} from "../../src/pricing/ConstantPricing.sol";
import {MockERC20} from "../MockERC20.sol";
import {MockEntropy} from "../MockEntropy.sol";

contract BatchRaffleTest is Test {
    BatchRaffle raffle;
    MockERC20 token;
    MockEntropy entropy;
    ConstantPricing pricing;
    
    address feeCollector = address(0x123);
    uint256 constant FEE_PERCENTAGE = 500; // 5%
    uint256 constant TICKET_PRICE = 100e6; // 100 USDC
    uint32 constant TOTAL_TICKETS = 100;
    
    function setUp() public {
        token = new MockERC20();
        entropy = new MockEntropy();
        pricing = new ConstantPricing();
        
        raffle = new BatchRaffle(
            address(entropy),
            address(pricing),
            feeCollector,
            FEE_PERCENTAGE
        );
        
        // Fund test accounts
        token.mint(address(this), 1000000e6);
        token.approve(address(raffle), type(uint256).max);
    }
    
    function testCreateRaffle() public returns (uint256) {
        // Ensure token is initialized before creating the raffle
        token = new MockERC20();
        
        BatchRaffle.TicketDistribution[] memory distribution = new BatchRaffle.TicketDistribution[](1);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 100,
            ticketQuantity: TOTAL_TICKETS
        });
        
        raffle.createRaffle(
            TOTAL_TICKETS,
            address(token),  // Ensure token is initialized
            uint96(TICKET_PRICE),
            distribution,
            100, // duration
            50 // minTicketsRequired
        );

        uint256 raffleId = raffle.raffleCounter();
        
        (
            address ticketToken,
            uint96 ticketTokenQuantity,
            ,   // endBlock
            ,   // minTicketsRequired
            ,   // ticketsRefunded
            ,   // ticketsMinted
            ,   // ticketsAvailable
            bool isActive,
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        
        assertEq(ticketToken, address(token), "Invalid ticket token");
        assertEq(ticketTokenQuantity, TICKET_PRICE, "Invalid ticket price");
        assertTrue(isActive, "Raffle should be active");
        
        // Fund test accounts
        token.mint(address(this), 1000000e6);
        token.approve(address(raffle), type(uint256).max);

        return raffleId;
    }
    
    function testBuyTickets() public returns (uint256) {
        // Setup raffle first
        uint256 raffleId = testCreateRaffle();
        
        uint32 quantity = 5;
        uint256 expectedCost = TICKET_PRICE * quantity;
        uint256 balanceBefore = token.balanceOf(address(this));
        
        raffle.buyTickets(raffleId, quantity);
        
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceBefore - balanceAfter, expectedCost);
        
        // Verify tickets assigned
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, address(this));
        assertEq(userTickets.length, quantity);
        return raffleId;
    }
    
    function testRefundTicket() public {
        uint256 raffleId = testBuyTickets();
        
        uint256 balanceBefore = token.balanceOf(address(this));
        raffle.refundTicket(raffleId, 0); // Refund first ticket
        uint256 balanceAfter = token.balanceOf(address(this));
        
        assertEq(balanceAfter - balanceBefore, TICKET_PRICE);
    }
    
//     function testClaimPrizeByTicketIds() public {
//         // Setup raffle first
//         testCreateRaffle();
        
//         // Buy tickets
//         uint32 quantity = 5;
//         raffle.buyTickets(0, quantity);
        
//         // Ensure minimum tickets are met
//         vm.startPrank(address(1));
//         token.mint(address(1), 1000000e6);
//         token.approve(address(raffle), type(uint256).max);
//         raffle.buyTickets(0, 55); // Buy remaining tickets to meet minimum
//         vm.stopPrank();
        
//         // Simulate raffle end and finalization
//         vm.roll(block.number + 101);
//         // entropy.setRandomNumber(123); // Set entropy first
//         vm.deal(address(this), 1 ether); // Ensure we have ETH for finalization
//         raffle.finalizeRaffle{value: 0.1 ether}(0);
//         // Verify raffle is finalized
//         (,,,,,,,,,bool isFinalized) = raffle.getRaffleInfo(0);
//         require(isFinalized, "Raffle not finalized");
        
//         // Get user's tickets
//         uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
//         uint256 balanceBefore = token.balanceOf(address(this));
        
//         raffle.claimPrizeByTicketIds(0, userTickets);
        
//         uint256 balanceAfter = token.balanceOf(address(this));
//         assertTrue(balanceAfter > balanceBefore, "Prize should be received");
        
//         // Try claiming again
//         vm.expectRevert("AlreadyClaimed");
//         raffle.claimPrizeByTicketIds(0, userTickets);
//     }
    
//     function testFuzzClaimPrizeByTicketIds(
//         uint32 ticketCount,
//         uint256 randomSeed
//     ) public {
//         vm.assume(ticketCount > 0 && ticketCount <= 25); // Half of minimum required
        
//         // Setup raffle
//         testCreateRaffle();
        
//         // Buy tickets for test account
//         raffle.buyTickets(0, ticketCount);
        
//         // Buy remaining tickets with different account to meet minimum
//         vm.startPrank(address(1));
//         token.mint(address(1), 1000000e6);
//         token.approve(address(raffle), type(uint256).max);
//         raffle.buyTickets(0, 50 - ticketCount); // Ensure minimum is met
//         vm.stopPrank();
        
//         // Simulate raffle end and finalization
//         vm.roll(block.number + 101);
//         // entropy.setRandomNumber(randomSeed);
//         vm.deal(address(this), 1 ether); // Ensure we have ETH for finalization
//         raffle.finalizeRaffle{value: 0.1 ether}(0);
//         // Verify raffle is finalized
//         (,,,,,,,,,bool isFinalized) = raffle.getRaffleInfo(0);
//         require(isFinalized, "Raffle not finalized");
        
//         // Get user's tickets
//         uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
//         uint256 balanceBefore = token.balanceOf(address(this));
        
//         raffle.claimPrizeByTicketIds(0, userTickets);
//         uint256 balanceAfter = token.balanceOf(address(this));
        
//         assertGe(balanceAfter, balanceBefore, "Balance should not decrease");
//     }
}