// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IRaffle.sol";

interface IRaffleState {
    struct RaffleInfo {
        uint256 raffleId;
        address ticketToken;
        uint96 ticketTokenQuantity;
        uint32 totalTickets;
        uint32 ticketsMinted;
        uint32 ticketsRefunded;
        uint32 ticketsAvailable;
        uint64 sequenceNumber;
        uint256 randomSeed;
        uint256 feeCollected;
        uint256 totalPoolTokenQuantity;
        uint32 minTicketsRequired;
        uint32 endBlock;
        bool isActive;
        bool isFinalized;
        bool isNull;

        // Packed into single slots above
        IRaffle.TicketDistribution[] ticketDistribution;
        mapping(address => uint256[]) userTickets;
        mapping(uint256 => IRaffle.PackedTicketInfo) ticketOwnersAndPrizes;
        mapping(address => bool) hasClaimed;
        mapping(uint256 => bool) isTicketClaimed;
        mapping(uint256 => uint256[]) winningTicketsPerPool;
        uint32[] refundedTicketIds;

    }

    function getRaffleInfo(uint256 raffleId) external view returns (
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
    );

    function getUserTickets(uint256 raffleId, address user) external view returns (uint256[] memory);
    function getWinningTicketsForPool(uint256 raffleId, uint256 poolIndex) external view returns (uint256[] memory);
    function getTicketInfo(uint256 raffleId, uint256 ticketId) external view returns (
        address owner,
        uint96 prizeShare,
        uint256 purchasePrice
    );
} 