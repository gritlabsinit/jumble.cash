// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {BatchRaffle} from "../src/implementations/BatchRaffle.sol";
import {IRaffle} from "../src/interfaces/IRaffle.sol";
import {MockEntropy} from "./MockEntropy.sol";
import {MockERC20} from "./MockERC20.sol";
import {ConstantPricing} from "../src/pricing/ConstantPricing.sol";

contract MockRaffle is BatchRaffle {  
    constructor(address entropyAddress, address pricing, address feeCollector, uint256 feePercentage) BatchRaffle(entropyAddress, pricing, feeCollector, feePercentage) {}
    function __entropyCallback(uint64 sequenceNumber, address provider, bytes32 randomNumber) external {
        super.entropyCallback(sequenceNumber, provider, randomNumber);
    } 
}

contract RaffleTest is Test {
    MockRaffle public raffle;
    MockERC20 public token;
    MockEntropy public mockEntropy;
    ConstantPricing public pricing;
    address public owner;
    address public user1;
    address public user2;
    address public entropyAddress;
    address public feeCollector;
    uint256 public feePercentage;

    // Add events for testing
    event RaffleStateUpdated(uint256 indexed raffleId, bool isActive);
    event RaffleDeclaredNull(uint256 indexed raffleId);

    uint256 constant FEE_PERCENTAGE = 500; // 5%
    uint256 constant TICKET_PRICE = 100e6; // 100 USDC
    uint32 constant TOTAL_TICKETS = 100;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        entropyAddress = makeAddr("entropy");
        feeCollector = makeAddr("feeCollector");
        feePercentage = 250; // 2.50%

        token = new MockERC20();
        mockEntropy = new MockEntropy();

        pricing = new ConstantPricing();
        raffle = new MockRaffle(address(mockEntropy), address(pricing), feeCollector, feePercentage);

        // Fund test accounts
        token.transfer(user1, 1000 * 10**18);
        token.transfer(user2, 1000 * 10**18);
    }

    // Helper function to create a basic raffle
    function createBasicRaffle() internal returns (uint256) {
        IRaffle.TicketDistribution[] memory distribution = new IRaffle.TicketDistribution[](2);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 70,
            ticketQuantity: 1
        });
        distribution[1] = IRaffle.TicketDistribution({
            fundPercentage: 30,
            ticketQuantity: 2
        });

        raffle.createRaffle(
            3, // totalTickets
            address(token),
            100 * 10**18, // ticketTokenQuantity
            distribution,
            100, // duration
            2 // minTicketsRequired
        );

        return raffle.raffleCounter();
    }

    function testCreateRaffleBasic() public returns (uint256) {
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
        
        return raffleId;
    }

    // Positive Tests
    function testCreateRaffle() public {
        uint256 raffleId = testCreateRaffleBasic();
        (
            address ticketToken,
            uint96 ticketTokenQuantity,
            ,   // endBlock
            ,   // minTicketsRequired
            ,   // totalSold
            ,   // availableTickets
            ,
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);

        assertEq(ticketToken, address(token), "Invalid ticket token");
        assertEq(ticketTokenQuantity, TICKET_PRICE, "Invalid ticket price");
    }

    function testBuyTickets() public {
        uint256 raffleId = createBasicRaffle();
        
        vm.startPrank(user1);
        token.approve(address(raffle), 100 * 10**18);
        raffle.buyTickets(raffleId, 1);
        vm.stopPrank();

        (
            ,   // ticketToken
            ,   // ticketTokenQuantity
            ,   // endBlock
            ,   // minTicketsRequired
            uint32 ticketsRefunded,
            uint32 ticketsMinted,
            ,   // ticketsAvailable
            ,   // isActive
            ,   // isFinalized
            
        ) = raffle.getRaffleInfo(raffleId);

        assertEq(ticketsMinted - ticketsRefunded, 1, "Invalid ticket count");
    }

    function testCompleteRaffleFlow() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), type(uint256).max);
        raffle.buyTickets(raffleId, 3);
        raffle.refundTicket(raffleId, 0);
        vm.stopPrank();

        (,,,,uint32 ticketsRefunded, uint32 ticketsMinted,, bool isActive,,) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted - ticketsRefunded, 2, "Invalid ticket count");

        // Move past end block
        vm.roll(block.number + 201);
        
        // Get the entropy fee and ensure we have enough ETH
        uint256 entropyFee = raffle.getSequenceFees();
        vm.deal(address(this), entropyFee);
        
        // Finalize raffle with the correct entropy fee
        raffle.finalizeRaffle{value: entropyFee}(raffleId);
        
        // Mock entropy callback
        vm.prank(entropyAddress);
        raffle.__entropyCallback(uint64(raffleId), entropyAddress, bytes32(uint256(1234)));
        
        // Select winners
        raffle.selectWinners(raffleId);
        
        // Verify raffle state before claiming
        (,,,,,,,, bool isFinalized, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isFinalized, "Raffle should be finalized");
        assertFalse(isNull, "Raffle should not be null");
        
        // Claim prize
        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        raffle.claimPrize(raffleId);
        uint256 balanceAfter = token.balanceOf(user1);
        
        assertTrue(balanceAfter > balanceBefore, "Prize should be claimed");
    }

    // Negative Tests
    function testFailCreateRaffleWithInvalidDistribution() public {
        IRaffle.TicketDistribution[] memory distribution = new IRaffle.TicketDistribution[](1);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 90, // Not 100%
            ticketQuantity: 3
        });

        raffle.createRaffle(
            3,
            address(token),
            100 * 10**18,
            distribution,
            100,
            2
        );
    }

    function testFailBuyTicketsWithoutApproval() public {
        uint256 raffleId = createBasicRaffle();
        
        vm.prank(user1);
        raffle.buyTickets(raffleId, 1);
    }

    function testFailFinalizeRaffleEarly() public {
        uint256 raffleId = createBasicRaffle();
        raffle.finalizeRaffle(raffleId);
    }

    // Fuzz Tests
    function testFuzz_CreateRaffleWithVariousTickets(
        uint32 totalTickets,
        uint96 ticketCost,
        uint32 duration
    ) public {
        vm.assume(totalTickets > 0 && totalTickets < 1000);
        vm.assume(ticketCost > 0 && ticketCost < 1000 * 10**18);
        vm.assume(duration > 0 && duration < 1000000);

        IRaffle.TicketDistribution[] memory distribution = new IRaffle.TicketDistribution[](1);
        distribution[0] = IRaffle.TicketDistribution({
            fundPercentage: 100,
            ticketQuantity: totalTickets
        });

        raffle.createRaffle(
            totalTickets,
            address(token),
            ticketCost,
            distribution,
            duration,
            1
        );
    }

    function testFuzz_BuyVariousTickets(uint32 quantity) public {
        vm.assume(quantity > 0 && quantity <= 3);
        
        uint256 raffleId = createBasicRaffle();
        uint256 ticketCost = 100 * 10**18;
        
        vm.startPrank(user1);
        // Safe multiplication for approval amount
        uint256 approvalAmount;
        unchecked {
            require(quantity <= type(uint256).max / ticketCost, "Approval amount overflow");
            approvalAmount = quantity * ticketCost;
        }
        
        token.approve(address(raffle), approvalAmount);
        raffle.buyTickets(raffleId, quantity);
        vm.stopPrank();

        (
            ,   // ticketToken
            ,   // ticketTokenQuantity
            ,   // endBlock
            ,   // minTicketsRequired
            uint32 ticketsRefunded,
            uint32 ticketsMinted,
            ,   // availableTickets
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted-ticketsRefunded, quantity);
    }

    // Edge Cases
    function testMinimumTicketsRequirement() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy only 1 ticket (minimum is 2)
        vm.startPrank(user1);
        token.approve(address(raffle), 100 * 10**18);
        raffle.buyTickets(raffleId, 1);
        vm.stopPrank();

        vm.roll(block.number + 101);
        raffle.finalizeRaffle(raffleId);

        (,,,,,,,,, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isNull);
    }

    function testRefundTicket() public {
        uint256 raffleId = createBasicRaffle();
        
        vm.startPrank(user1);
        token.approve(address(raffle), 100 * 10**18);
        raffle.buyTickets(raffleId, 1);
        raffle.refundTicket(raffleId, 0);
        vm.stopPrank();

        (
            ,   // ticketToken
            ,   // ticketTokenQuantity
            ,   // endBlock
            ,   // minTicketsRequired
            uint32 ticketsRefunded,
            uint32 ticketsMinted,
            ,   // availableTickets
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted-ticketsRefunded, 0);
    }

    function testTicketLifecycle() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy enough tickets to meet minimum requirement
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 2); // Buy minimum required tickets
        
        // Verify purchase
        (,,,,uint32 ticketsRefunded, uint32 ticketsMinted,,,,) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted - ticketsRefunded, 2, "Invalid ticket count");
        
        // Rest of the test...
        vm.stopPrank();
    }

    function testGasEfficiency() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 1000 * 10**18); // Increase approval amount
        
        uint256 gasBefore = gasleft();
        raffle.buyTickets(raffleId, 2); // Buy minimum required tickets
        uint256 buyGas = gasBefore - gasleft();
        
        // Get user tickets
        uint256[] memory tickets = raffle.getUserTickets(raffleId, user1);
        require(tickets.length > 0, "No tickets bought");
        
        gasBefore = gasleft();
        raffle.refundTicket(raffleId, uint32(tickets[0]));
        uint256 refundGas = gasBefore - gasleft();
        
        // Gas assertions
        assertLt(buyGas, 1000000);
        assertLt(refundGas, 100000);
        vm.stopPrank();
    }

    // Test state updates
    function testRaffleStateUpdate() public {
        uint256 raffleId = createBasicRaffle();
        bool isFinalized;

        // Verify initial state
        (,,,,,,,bool isActive,,) = raffle.getRaffleInfo(raffleId);
        assertTrue(isActive, "Raffle should start active");
        
        // Move past end block
        vm.roll(block.number + 101);
        
        // Finalize raffle
        raffle.finalizeRaffle(raffleId);
        // Verify final state
        (
            ,   // ticketToken
            ,   // ticketTokenQuantity
            ,   // endBlock
            ,   // minTicketsRequired
            ,   // ticketsRefunded
            ,   // ticketsMinted
            ,   // availableTickets
            isActive,   // isActive
            isFinalized,   // isFinalized
            // bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        assertFalse(isActive, "Raffle should be inactive");
        assertTrue(isFinalized, "Raffle should be finalized");
    }

    function testNullRaffleOnInsufficientTickets() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy only 1 ticket when minimum is 2
        vm.startPrank(user1);
        token.approve(address(raffle), 100 * 10**18);
        raffle.buyTickets(raffleId, 1);
        vm.stopPrank();
        
        // Move past end block
        vm.roll(block.number + 101);
        
        // Finalize raffle
        raffle.finalizeRaffle(raffleId);
        
        // Check if raffle is null
        (,,,,,,,, bool isFinalized, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isNull, "Raffle should be null");
        assertTrue(isFinalized, "Raffle should be finalized");
    }

    function testWinnerSelection() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), type(uint256).max);
        raffle.buyTickets(raffleId, 3);
        vm.stopPrank();

        (,,,,uint32 ticketsRefunded, uint32 ticketsMinted,, bool isActive,,) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted - ticketsRefunded, 3, "Invalid ticket count");

        // Move past end block
        vm.roll(block.number + 201);
        
        // Get the entropy fee and ensure we have enough ETH
        uint256 entropyFee = raffle.getSequenceFees();
        vm.deal(address(this), entropyFee);
        
        // Finalize raffle with the correct entropy fee
        raffle.finalizeRaffle{value: entropyFee}(raffleId);
        
        // Mock entropy callback
        vm.prank(entropyAddress);
        raffle.__entropyCallback(uint64(raffleId), entropyAddress, bytes32(uint256(1234)));
        
        // Select winners
        raffle.selectWinners(raffleId);
    }

    function testClaimPrize() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), type(uint256).max);
        raffle.buyTickets(raffleId, 3);
        vm.stopPrank();

        (,,,,uint32 ticketsRefunded, uint32 ticketsMinted,, bool isActive,,) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted - ticketsRefunded, 3, "Invalid ticket count");

        // Move past end block
        vm.roll(block.number + 201);
        
        // Get the entropy fee and ensure we have enough ETH
        uint256 entropyFee = raffle.getSequenceFees();
        vm.deal(address(this), entropyFee);
        
        // Finalize raffle with the correct entropy fee
        raffle.finalizeRaffle{value: entropyFee}(raffleId);
        
        // Mock entropy callback
        vm.prank(entropyAddress);
        raffle.__entropyCallback(uint64(raffleId), entropyAddress, bytes32(uint256(1234)));
        
        // Select winners
        raffle.selectWinners(raffleId);
        
        // Verify raffle state before claiming
        (,,,,,,,, bool isFinalized, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isFinalized, "Raffle should be finalized");
        assertFalse(isNull, "Raffle should not be null");
        
        // Claim prize
        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        raffle.claimPrize(raffleId);
        uint256 balanceAfter = token.balanceOf(user1);
        
        assertTrue(balanceAfter > balanceBefore, "Prize should be claimed");
    }

    // Add helper function to get ticket info
    function getTicketInfo(uint256 raffleId, uint256 ticketId) 
        external 
        view 
        returns (address _owner, uint96 _prizeShare, uint256 _purchasePrice) 
    {
        (_owner, _prizeShare, _purchasePrice) = raffle.getTicketInfo(raffleId, ticketId);
    }

    function testRefundTicketsByIds() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        
        // Get user's tickets
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        assertEq(userTickets.length, 3, "Should have 3 tickets");
        
        // Create array of ticket IDs to refund
        uint256[] memory ticketsToRefund = new uint256[](2);
        ticketsToRefund[0] = userTickets[0];
        ticketsToRefund[1] = userTickets[1];
        
        // Get balance before refund
        uint256 balanceBefore = token.balanceOf(user1);
        
        // Refund tickets
        raffle.refundTicketsByTicketIds(raffleId, ticketsToRefund);
        vm.stopPrank();
        
        // Verify refund
        uint256 balanceAfter = token.balanceOf(user1);
        assertTrue(balanceAfter > balanceBefore, "Should have received refund");
        
        // Verify ticket state
        (,,,,uint32 ticketsRefunded, uint32 ticketsMinted,,,,) = raffle.getRaffleInfo(raffleId);
        assertEq(ticketsMinted - ticketsRefunded, 1, "Should have 1 ticket remaining");
    }

    function testClaimPrizeByTicketIds() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        
        // Get user's tickets
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        vm.stopPrank();
        
        // Move past end block
        vm.roll(block.number + 201);
        
        // Get the entropy fee and ensure we have enough ETH
        uint256 entropyFee = raffle.getSequenceFees();
        vm.deal(address(this), entropyFee);
        
        // Finalize raffle
        raffle.finalizeRaffle{value: entropyFee}(raffleId);
        
        // Mock entropy callback
        vm.prank(entropyAddress);
        raffle.__entropyCallback(uint64(raffleId), entropyAddress, bytes32(uint256(1234)));
        
        // Select winners
        raffle.selectWinners(raffleId);
        
        // Verify raffle state before claiming
        (,,,,,,,, bool isFinalized, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isFinalized, "Raffle should be finalized");
        assertFalse(isNull, "Raffle should not be null");
        
        // Claim prizes for specific tickets
        uint256[] memory ticketsToClaim = new uint256[](2);
        ticketsToClaim[0] = userTickets[0];
        ticketsToClaim[1] = userTickets[1];
        
        uint256 balanceBefore = token.balanceOf(user1);
        
        vm.prank(user1);
        raffle.claimPrizeByTicketIds(raffleId, ticketsToClaim);
        
        uint256 balanceAfter = token.balanceOf(user1);
        assertTrue(balanceAfter > balanceBefore, "Should have received prize");
    }

    // Add negative test cases
    function testFailRefundTicketsByIdsNotOwner() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets as user1
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        vm.stopPrank();
        
        // Try to refund as user2
        vm.startPrank(user2);
        uint256[] memory ticketsToRefund = new uint256[](1);
        ticketsToRefund[0] = userTickets[0];
        // Expect specific revert message
        vm.expectRevert(bytes4(keccak256("NotTicketOwner()")));
        raffle.refundTicketsByTicketIds(raffleId, ticketsToRefund);
        vm.stopPrank();
    }

    function testFailClaimPrizeByTicketIdsNotFinalized() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        
        // Try to claim before finalization
        uint256[] memory ticketsToClaim = new uint256[](1);
        ticketsToClaim[0] = userTickets[0];
        raffle.claimPrizeByTicketIds(raffleId, ticketsToClaim); // Should revert
        vm.stopPrank();
    }

    function testFailRefundTicketsByIdsAfterEnd() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        
        // Move past end block
        vm.roll(block.number + 201);
        
        // Try to refund after end
        uint256[] memory ticketsToRefund = new uint256[](1);
        ticketsToRefund[0] = userTickets[0];
        // Expect specific revert message
        vm.expectRevert("RaffleNotActive()");
        raffle.refundTicketsByTicketIds(raffleId, ticketsToRefund);
        vm.stopPrank();
    }

    function testRefundAndClaimMix() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        
        // Get user's tickets
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        
        // Refund one ticket
        uint256[] memory ticketsToRefund = new uint256[](1);
        ticketsToRefund[0] = userTickets[0];
        raffle.refundTicketsByTicketIds(raffleId, ticketsToRefund);
        vm.stopPrank();
        
        // Finalize raffle
        vm.roll(block.number + 201);
        uint256 entropyFee = raffle.getSequenceFees();
        vm.deal(address(this), entropyFee);
        raffle.finalizeRaffle{value: entropyFee}(raffleId);
        
        // Mock entropy callback and select winners
        vm.prank(entropyAddress);
        raffle.__entropyCallback(uint64(raffleId), entropyAddress, bytes32(uint256(1234)));
        raffle.selectWinners(raffleId);
        
        // Claim remaining tickets
        uint256[] memory ticketsToClaim = new uint256[](2);
        ticketsToClaim[0] = userTickets[1];
        ticketsToClaim[1] = userTickets[2];
        
        vm.prank(user1);
        raffle.claimPrizeByTicketIds(raffleId, ticketsToClaim);
    }
}