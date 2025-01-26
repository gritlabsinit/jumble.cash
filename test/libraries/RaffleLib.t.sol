// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {RaffleLib} from "../../src/libraries/RaffleLib.sol";
import {IRaffle} from "../../src/interfaces/IRaffle.sol";

contract RaffleLibTest is Test {
    // Mock storage for ticket info
    mapping(uint256 => IRaffle.PackedTicketInfo) internal ticketInfo;

    function setUp() public {
        // Setup any initial state if needed
        ticketInfo[1] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 100,
            purchasePrice: 1 ether
        });
    }

    function testCalculatePrizeEmptyTickets() public view  {
        uint256[] memory emptyTickets = new uint256[](0);
        uint256 prize = RaffleLib.calculatePrize(address(this), emptyTickets, ticketInfo);
        assertEq(prize, 0, "Empty tickets should return 0 prize");
    }

    function testCalculatePrizeSingleTicket() public {
        uint256[] memory tickets = new uint256[](1);
        tickets[0] = 1;
        
        ticketInfo[1] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 100,
            purchasePrice: 1 ether
        });

        uint256 prize = RaffleLib.calculatePrize(address(this), tickets, ticketInfo);
        assertEq(prize, 100, "Single ticket should return correct prize");
    }

    function testCalculatePrizeMultipleTickets() public {
        uint256[] memory tickets = new uint256[](3);
        tickets[0] = 1;
        tickets[1] = 2;
        tickets[2] = 3;
        
        ticketInfo[1] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 100,
            purchasePrice: 1 ether
        });
        ticketInfo[2] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 200,
            purchasePrice: 1 ether
        });
        ticketInfo[3] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 300,
            purchasePrice: 1 ether
        });

        uint256 prize = RaffleLib.calculatePrize(address(this), tickets, ticketInfo);
        assertEq(prize, 600, "Multiple tickets should sum prizes correctly");
    }

    function testCalculatePrizeSomeZeroPrizes() public {
        uint256[] memory tickets = new uint256[](3);
        tickets[0] = 1;
        tickets[1] = 2;
        tickets[2] = 3;
        
        ticketInfo[1] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 100,
            purchasePrice: 1 ether
        });
        ticketInfo[2] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 0,
            purchasePrice: 1 ether
        });
        ticketInfo[3] = IRaffle.PackedTicketInfo({
            owner: address(this),
            prizeShare: 300,
            purchasePrice: 1 ether
        });

        uint256 prize = RaffleLib.calculatePrize(address(this), tickets, ticketInfo);
        assertEq(prize, 400, "Should handle zero prizes correctly");
    }

    function testSelectWinnersSingleWinner() public pure {
        uint256[] memory tickets = new uint256[](5);
        tickets[0] = 10;
        tickets[1] = 20;
        tickets[2] = 30;
        tickets[3] = 40;
        tickets[4] = 50;

        uint256[] memory winners = RaffleLib.selectWinners(
            tickets,
            12345, // seed
            0,     // startIndex
            1      // count
        );

        assertEq(winners.length, 1, "Should return single winner");
        assertTrue(
            winners[0] == 10 || winners[0] == 20 || winners[0] == 30 || 
            winners[0] == 40 || winners[0] == 50,
            "Winner should be one of the tickets"
        );
    }

    function testSelectWinnersMultipleWinners() public pure {
        uint256[] memory tickets = new uint256[](5);
        tickets[0] = 10;
        tickets[1] = 20;
        tickets[2] = 30;
        tickets[3] = 40;
        tickets[4] = 50;

        uint256[] memory winners = RaffleLib.selectWinners(
            tickets,
            12345, // seed
            0,     // startIndex
            3      // count
        );

        assertEq(winners.length, 3, "Should return three winners");
        for (uint256 i = 0; i < winners.length; i++) {
            assertTrue(
                winners[i] == 10 || winners[i] == 20 || winners[i] == 30 || 
                winners[i] == 40 || winners[i] == 50,
                "Each winner should be one of the tickets"
            );
        }
    }

    function testSelectWinnersWithStartIndex() public pure {
        uint256[] memory tickets = new uint256[](5);
        tickets[0] = 10;
        tickets[1] = 20;
        tickets[2] = 30;
        tickets[3] = 40;
        tickets[4] = 50;

        uint256[] memory winners = RaffleLib.selectWinners(
            tickets,
            12345, // seed
            2,     // startIndex
            2      // count
        );

        assertEq(winners.length, 2, "Should return two winners");
        for (uint256 i = 0; i < winners.length; i++) {
            assertTrue(
                winners[i] == 30 || winners[i] == 40 || winners[i] == 50,
                "Winners should only be from tickets after startIndex"
            );
        }
    }

    function testFuzzCalculatePrize(
        uint256[] calldata prizeShares,
        uint256[] calldata purchasePrices
    ) public {
        uint256 length = bound(prizeShares.length, 1, 100);
        vm.assume(prizeShares.length >= length && purchasePrices.length >= length);

        // Setup tickets
        uint96 maxPrizeShare = 1e8;
        uint256 expectedPrize = 0;
        uint256[] memory tickets = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            uint96 prizeShare = uint96(bound(prizeShares[i], 0, maxPrizeShare));
            
            ticketInfo[i] = IRaffle.PackedTicketInfo({
                owner: address(this),
                prizeShare: uint96(prizeShare),
                purchasePrice: purchasePrices[i]
            });
            tickets[i] = i;
            expectedPrize += prizeShare;
        }

        emit log_named_uint("expectedPrize", expectedPrize);

        uint256 actualPrize = RaffleLib.calculatePrize(address(this), tickets, ticketInfo);
        assertEq(actualPrize, expectedPrize, "Prize calculation mismatch");
    }

    function testFuzzSelectWinners(
        uint256[] calldata tickets,
        uint256 seed,
        uint8 count,
        uint8 startIndex
    ) public pure {
        vm.assume(tickets.length > 0 && tickets.length < 1000);
        vm.assume(count > 0 && count <= tickets.length);
        vm.assume(startIndex < tickets.length);
        vm.assume(tickets.length - startIndex >= count);

        uint256[] memory winners = RaffleLib.selectWinners(
            tickets,
            seed,
            startIndex,
            count
        );

        assertEq(winners.length, count, "Should return requested number of winners");
        
        // Verify all winners are valid tickets
        for (uint256 i = 0; i < winners.length; i++) {
            bool found = false;
            for (uint256 j = startIndex; j < tickets.length; j++) {
                if (winners[i] == tickets[j]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "Winner should be from valid ticket range");
        }
    }
}