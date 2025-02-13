// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IRaffleState.sol";
import "../interfaces/IRaffle.sol";

abstract contract RaffleStorage is IRaffleState {
    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => uint256) public sequenceNumberToRaffleId;
    
    uint256 public raffleCounter;

    function getRaffleInfo(uint256 raffleId) external view override returns (
        address ticketToken,
        uint96 ticketTokenQuantity,
        uint32 endBlock,
        IRaffle.TicketDistribution[] memory ticketDistribution,
        uint32 totalTickets,
        uint32 minTicketsRequired,
        uint32 ticketsRefunded,
        uint32 ticketsMinted,
        uint32 ticketsAvailable,
        bool isActive,
        bool isFinalized,
        bool isNull
    ) {
        RaffleInfo storage raffle = raffles[raffleId];
        return (
            raffle.ticketToken,
            raffle.ticketTokenQuantity,
            raffle.endBlock,
            raffle.ticketDistribution,
            raffle.totalTickets,
            raffle.minTicketsRequired,
            raffle.ticketsRefunded,
            raffle.ticketsMinted,
            raffle.ticketsAvailable,
            raffle.isActive,
            raffle.isFinalized,
            raffle.isNull
        );
    }

    function getUserTickets(uint256 raffleId, address user) external view returns (uint256[] memory) {
        uint256[] memory tickets = raffles[raffleId].userTickets[user];
        // Filter out tickets that are not owned by the user
        uint256[] memory result = new uint256[](tickets.length);
        uint256 index = 0;
        for (uint256 i = 0; i < tickets.length; i++) {
            if (raffles[raffleId].ticketOwnersAndPrizes[tickets[i]].owner == user) {
                result[index] = tickets[i];
                index++;
            }
        }
        // remove the empty slots
        uint256[] memory filteredResult = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            filteredResult[i] = result[i];
        }
        return filteredResult;
    }

    function getWinningTicketsForPool(uint256 raffleId, uint256 poolIndex) external view returns (uint256[] memory) {
        return raffles[raffleId].winningTicketsPerPool[poolIndex];
    }

    function getTicketInfo(uint256 raffleId, uint256 ticketId) external view returns (
        address owner,
        uint96 prizeShare,
        uint256 purchasePrice
    ) {
        IRaffle.PackedTicketInfo memory info = raffles[raffleId].ticketOwnersAndPrizes[ticketId];
        return (info.owner, info.prizeShare, info.purchasePrice);
    }
} 