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
        return raffles[raffleId].userTickets[user];
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