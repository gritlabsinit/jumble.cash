// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IRaffle.sol";

library RaffleLib {
    function calculatePrize(
        uint256[] memory userTickets,
        mapping(uint256 => IRaffle.PackedTicketInfo) storage ticketInfo
    ) internal view returns (uint256) {
        if (userTickets.length == 0) return 0;

        uint256 prize;
        for (uint256 i; i < userTickets.length;) {
            IRaffle.PackedTicketInfo memory info = ticketInfo[userTickets[i]];
            if (info.prizeShare > 0) {
                unchecked {
                    prize += info.prizeShare;
                }
            }
            unchecked { ++i; }
        }
        return prize;
    }

    function selectWinners(
        uint256[] memory tickets,
        uint256 seed,
        uint256 startIndex,
        uint256 count
    ) internal pure returns (uint256[] memory) {
        uint256[] memory winners = new uint256[](count);
        for (uint256 i; i < count;) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint256 winnerIdx = startIndex + (seed % (tickets.length - startIndex));
            winners[i] = tickets[winnerIdx];
            unchecked { ++i; }
        }
        return winners;
    }
} 