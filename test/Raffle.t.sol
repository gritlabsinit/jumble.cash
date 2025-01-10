// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract MockRaffle is Raffle {
    constructor(address _entropyAddress, address _feeCollector, uint256 _feePercentage) Raffle(_entropyAddress, _feeCollector, _feePercentage) {}

    function _entropyCallback(uint64 sequenceNumber, address provider, bytes32 randomNumber) external override {
        super.entropyCallback(sequenceNumber, provider, randomNumber);
    }
}

contract RaffleTest is Test {
    MockRaffle public raffle;
    MockERC20 public token;
    address public owner;
    address public user1;
    address public user2;
    address public entropyAddress;
    address public feeCollector;
    uint256 public feePercentage;

    // Add events for testing
    event RaffleStateUpdated(uint256 indexed raffleId, bool isActive);
    event RaffleDeclaredNull(uint256 indexed raffleId);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        entropyAddress = makeAddr("entropy");
        feeCollector = makeAddr("feeCollector");
        feePercentage = 250; // 2.50%

        token = new MockERC20();
        raffle = new MockRaffle(entropyAddress, feeCollector, feePercentage);

        // Fund test accounts
        token.transfer(user1, 1000 * 10**18);
        token.transfer(user2, 1000 * 10**18);
    }

    // Helper function to create a basic raffle
    function createBasicRaffle() internal returns (uint256) {
        Raffle.TicketDistribution[] memory distribution = new Raffle.TicketDistribution[](2);
        distribution[0] = Raffle.TicketDistribution({
            fundPercentage: 70,
            ticketQuantity: 1
        });
        distribution[1] = Raffle.TicketDistribution({
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

    // Positive Tests
    function testCreateRaffle() public {
        uint256 raffleId = createBasicRaffle();
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

        assertEq(ticketToken, address(token));
        assertEq(ticketTokenQuantity, 100 * 10**18);
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
            uint32 totalSold,
            ,
            ,   // availableTickets
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);

        assertEq(totalSold, 1);
    }

    function testCompleteRaffleFlow() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 200 * 10**18);
        raffle.buyTickets(raffleId, 2);
        vm.stopPrank();

        // Move blocks forward
        vm.roll(block.number + 101);

        // Finalize raffle
        raffle.finalizeRaffle(raffleId);

        // Claim prize
        vm.prank(user1);
        raffle.claimPrize(raffleId);
    }

    // Negative Tests
    function testFailCreateRaffleWithInvalidDistribution() public {
        Raffle.TicketDistribution[] memory distribution = new Raffle.TicketDistribution[](1);
        distribution[0] = Raffle.TicketDistribution({
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

        Raffle.TicketDistribution[] memory distribution = new Raffle.TicketDistribution[](1);
        distribution[0] = Raffle.TicketDistribution({
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
            uint32 totalSold,
            ,
            ,   // availableTickets
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        assertEq(totalSold, quantity);
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
            uint32 totalSold,
            ,
            ,   // availableTickets
            ,   // isActive
            ,   // isFinalized
            bool isNull
        ) = raffle.getRaffleInfo(raffleId);
        assertEq(totalSold, 0);
    }

    function testTicketLifecycle() public {
        // Create raffle
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 5e18);
        raffle.buyTickets(raffleId, 5);
        
        // Verify purchase
        assertEq(raffle.getUserTickets(raffleId, user1).length, 5);
        
        // Refund a ticket
        uint256 ticketId = raffle.getUserTickets(raffleId, user1)[0];
        raffle.refundTicket(raffleId, uint32(ticketId));
        // Verify refund
        assertEq(raffle.getUserTickets(raffleId, user1).length, 4);
        
        // Finalize raffle
        vm.roll(block.number + 101);
        raffle.finalizeRaffle(raffleId);
        
        // Verify winners don't include refunded ticket
        uint256[] memory winners = raffle.getWinningTicketsForPool(raffleId, 0);
        for (uint256 i = 0; i < winners.length; i++) {
            assertFalse(winners[i] == ticketId);
        }
    }

    function testGasEfficiency() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy and refund multiple tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 100e18);
        
        uint256 gasBefore = gasleft();
        raffle.buyTickets(raffleId, 50);
        uint256 buyGas = gasBefore - gasleft();
        
        uint256[] memory tickets = raffle.getUserTickets(raffleId, user1);
        gasBefore = gasleft();
        raffle.refundTicket(raffleId, uint32(tickets[0]));
        uint256 refundGas = gasBefore - gasleft();
        
        // Gas should be reasonable
        assertLt(buyGas, 1000000);
        assertLt(refundGas, 100000);
    }

    // Test state updates
    function testRaffleStateUpdate() public {
        uint256 raffleId = createBasicRaffle();
        
        // Move past end block
        vm.roll(block.number + 101);
        
        // Expect state update events
        vm.expectEmit(true, false, false, true);
        emit RaffleStateUpdated(raffleId, false);
        
        raffle.checkRaffleState(raffleId);
        
        (,,,,,,, bool isActive,,) = raffle.getRaffleInfo(raffleId);
        assertFalse(isActive);
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
        
        // Expect both state update and null raffle events
        vm.expectEmit(true, false, false, true);
        emit RaffleStateUpdated(raffleId, false);
        vm.expectEmit(true, false, false, true);
        emit RaffleDeclaredNull(raffleId);
        
        raffle.checkRaffleState(raffleId);
        
        (,,,,,,,, bool isFinalized, bool isNull) = raffle.getRaffleInfo(raffleId);
        assertTrue(isNull);
    }

    function testWinnerSelection() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy all tickets
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        vm.stopPrank();
        
        // Move past end block and finalize
        vm.roll(block.number + 101);
        raffle.finalizeRaffle(raffleId);
        
        // Mock entropy callback
        vm.prank(entropyAddress);
        bytes32 randomNumber = bytes32(uint256(1234));
        raffle._entropyCallback(1, entropyAddress, randomNumber);
        
        // Select winners
        raffle.selectWinners(raffleId);
        
        // Verify prize shares are set
        uint256[] memory userTickets = raffle.getUserTickets(raffleId, user1);
        for (uint256 i = 0; i < userTickets.length; i++) {
            // get ticket info
            (address _owner, uint96 prizeShare) = raffle.getTicketInfo(raffleId, userTickets[i]);
            assertEq(owner, user1);
            assertTrue(prizeShare >= 0);
        }
    }

    function testClaimPrize() public {
        uint256 raffleId = createBasicRaffle();
        
        // Buy tickets and finalize raffle
        vm.startPrank(user1);
        token.approve(address(raffle), 300 * 10**18);
        raffle.buyTickets(raffleId, 3);
        vm.stopPrank();
        
        vm.roll(block.number + 101);
        raffle.finalizeRaffle(raffleId);
        
        // Mock winner selection
        vm.prank(entropyAddress);
        raffle._entropyCallback(1, entropyAddress, bytes32(uint256(1234)));
        raffle.selectWinners(raffleId);
        
        // Claim prize
        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        raffle.claimPrize(raffleId);
        uint256 balanceAfter = token.balanceOf(user1);
        
        assertTrue(balanceAfter > balanceBefore);
    }

    // Add helper function to get ticket info
    function getTicketInfo(uint256 raffleId, uint256 ticketId) 
        external 
        view 
        returns (address _owner, uint96 _prizeShare) 
    {
        (_owner, _prizeShare) = raffle.getTicketInfo(raffleId, ticketId);
    }
}