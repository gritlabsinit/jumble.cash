// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IRaffle.sol";

library RaffleLib {
    function calculatePrize(
        address user,
        uint256[] memory userTickets,
        mapping(uint256 => IRaffle.PackedTicketInfo) storage ticketInfo
    ) internal view returns (uint256) {
        if (userTickets.length == 0) return 0;

        uint256 prize = 0;
        for (uint256 i = 0; i < userTickets.length; i++) {
            IRaffle.PackedTicketInfo memory info = ticketInfo[userTickets[i]];
            if (info.prizeShare > 0 && info.owner == user) {
                prize += info.prizeShare;
            }
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
        for (uint256 i = 0; i < count; i++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint256 winnerIdx = startIndex + (seed % (tickets.length - startIndex));
            winners[i] = tickets[winnerIdx];
        }
        return winners;
    }
} 