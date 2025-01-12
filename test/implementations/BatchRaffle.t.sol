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
    
    function testCreateRaffle() public {
        BatchRaffle.TicketDistribution[] memory distribution = new BatchRaffle.TicketDistribution[](1);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 100,
            ticketQuantity: TOTAL_TICKETS
        });
        
        raffle.createRaffle(
            TOTAL_TICKETS,
            address(token),
            uint96(TICKET_PRICE),
            distribution,
            100, // duration
            50 // minTicketsRequired
        );
        
        (
            address ticketToken,
            uint96 ticketTokenQuantity,
            ,,,,,
            bool isActive,,
        ) = raffle.getRaffleInfo(0);
        
        assertEq(ticketToken, address(token));
        assertEq(ticketTokenQuantity, TICKET_PRICE);
        assertTrue(isActive);
    }
    
    function testBuyTickets() public {
        // Setup raffle first
        testCreateRaffle();
        
        uint32 quantity = 5;
        uint256 expectedCost = TICKET_PRICE * quantity;
        uint256 balanceBefore = token.balanceOf(address(this));
        
        raffle.buyTickets(0, quantity);
        
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceBefore - balanceAfter, expectedCost);
        
        // Verify tickets assigned
        uint256[] memory userTickets = raffle.getUserTickets(0, address(this));
        assertEq(userTickets.length, quantity);
    }
    
    function testRefundTicket() public {
        testBuyTickets();
        
        uint256 balanceBefore = token.balanceOf(address(this));
        raffle.refundTicket(0, 0); // Refund first ticket
        uint256 balanceAfter = token.balanceOf(address(this));
        
        assertEq(balanceAfter - balanceBefore, TICKET_PRICE);
    }
}