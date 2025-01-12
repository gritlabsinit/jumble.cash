// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRaffle {
    struct TicketDistribution {
        uint96 fundPercentage;
        uint96 ticketQuantity;
    }

    struct PackedTicketInfo {
        address owner;
        uint96 prizeShare;
        uint256 purchasePrice;
    }
    // Custom errors for gas optimization
    error InvalidDistribution();
    error RaffleNotActive();
    error InsufficientTickets();
    error RaffleNotEnded();
    error RaffleAlreadyFinalized();
    error RaffleNotFinalized();
    error AlreadyClaimed();
    error TicketNotOwned();
    error TicketAlreadyRefunded();
    error RaffleIsNull();
    error InvalidTicketId();
    error ZeroAddress();
    error RaffleExpired();


    event RaffleCreated(uint256 indexed raffleId, address creator, uint256 totalTickets);
    event TicketsPurchased(uint256 indexed raffleId, address indexed buyer, uint256 quantity);
    event TicketRefunded(uint256 indexed raffleId, address indexed user, uint256 ticketId);
    event SequenceNumberRequested(uint256 indexed raffleId, uint64 sequenceNumber);
    event RaffleFinalized(uint256 indexed raffleId, uint256 randomSeed);
    event RaffleDeclaredNull(uint256 indexed raffleId);
    event PrizeClaimed(uint256 indexed raffleId, address indexed winner, uint256 amount);
    event FeeCollected(uint256 indexed raffleId, uint256 amount);
    event PoolPrizeCreated(uint256 indexed raffleId, uint256 poolIndex, uint256 poolPrize, uint256 prizePerWinner);
    event WinnersSelected(uint256 indexed raffleId, uint32 validTickets);
    event RaffleStateUpdated(uint256 indexed raffleId, bool isActive);
    event PrizeClaimedForTicketIds(uint256 indexed raffleId, address indexed winner, uint256 amount, uint256[] ticketIds);
    event RefundClaimedForTicketIds(uint256 indexed raffleId, address indexed user, uint256 amount, uint256[] ticketIds);

    function createRaffle(
        uint32 totalTickets,
        address ticketToken,
        uint96 ticketTokenQuantity,
        TicketDistribution[] calldata distribution,
        uint32 duration,
        uint32 minTicketsRequired
    ) external;

    function buyTickets(uint256 raffleId, uint32 quantity) external;
    function claimPrize(uint256 raffleId) external;
    function claimRefund(uint256 raffleId) external;
    function finalizeRaffle(uint256 raffleId) external payable;
    function refundTicket(uint256 raffleId, uint32 ticketId) external;
}