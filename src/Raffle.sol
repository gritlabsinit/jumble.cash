// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Raffle
 * @notice A gas-optimized raffle contract with refund functionality and minimum ticket requirements
 */
contract Raffle is ReentrancyGuard, Ownable {
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

    struct TicketDistribution {
        uint96 fundPercentage; // Using uint96 to pack with ticketQuantity
        uint96 ticketQuantity;
    }

    struct RaffleInfo {
        address ticketToken;
        uint96 ticketTokenQuantity;
        uint32 endBlock;
        uint32 minTicketsRequired;
        uint32 totalSold;
        uint32 availableTickets;
        bool isActive;
        bool isFinalized;
        bool isNull;
        // Packed into single slots above
        mapping(address => uint256[]) userTickets;
        mapping(uint256 => address) ticketOwners;
        mapping(address => bool) hasClaimed;
        mapping(uint256 => bool) isTicketRefunded;
        TicketDistribution[] ticketDistribution;
        mapping(uint256 => uint256[]) winningTicketsPerPool;
    }

    // State variables
    mapping(uint256 => RaffleInfo) public raffles;
    uint256 public raffleCounter;

    // Events
    event RaffleCreated(uint256 indexed raffleId, address creator, uint256 totalTickets);
    event TicketsPurchased(uint256 indexed raffleId, address indexed buyer, uint256 quantity);
    event TicketRefunded(uint256 indexed raffleId, address indexed user, uint256 ticketId);
    event RaffleFinalized(uint256 indexed raffleId, uint256 randomSeed);
    event RaffleDeclaredNull(uint256 indexed raffleId);
    event PrizeClaimed(uint256 indexed raffleId, address indexed winner, uint256 amount);

    /**
     * @notice Creates a new raffle
     * @param totalTickets Total number of tickets available
     * @param ticketToken ERC20 token used for tickets
     * @param ticketTokenQuantity Cost per ticket in tokens
     * @param distribution Array of prize distributions
     * @param duration Duration in blocks
     * @param minTicketsRequired Minimum tickets that must be sold
     */
    function createRaffle(
        uint32 totalTickets,
        address ticketToken,
        uint96 ticketTokenQuantity,
        TicketDistribution[] calldata distribution,
        uint32 duration,
        uint32 minTicketsRequired
    ) external {
        if (ticketToken == address(0)) revert ZeroAddress();
        
        uint256 totalTicketsInDist;
        uint256 totalPercentage;
        
        for (uint256 i = 0; i < distribution.length;) {
            totalTicketsInDist += distribution[i].ticketQuantity;
            totalPercentage += distribution[i].fundPercentage;
            unchecked { ++i; }
        }
        
        if (totalTicketsInDist != totalTickets || totalPercentage != 100) {
            revert InvalidDistribution();
        }

        uint256 raffleId = ++raffleCounter;
        RaffleInfo storage raffle = raffles[raffleId];
        
        raffle.ticketToken = ticketToken;
        raffle.ticketTokenQuantity = ticketTokenQuantity;
        raffle.endBlock = uint32(block.number + duration);
        raffle.minTicketsRequired = minTicketsRequired;
        raffle.availableTickets = totalTickets;
        raffle.isActive = true;

        for (uint256 i = 0; i < distribution.length;) {
            raffle.ticketDistribution.push(distribution[i]);
            unchecked { ++i; }
        }

        emit RaffleCreated(raffleId, msg.sender, totalTickets);
    }

    /**
     * @notice Purchase tickets for a raffle
     * @param raffleId ID of the raffle
     * @param quantity Number of tickets to purchase
     */
    function buyTickets(uint256 raffleId, uint32 quantity) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isActive || block.number >= raffle.endBlock) revert RaffleNotActive();
        if (raffle.availableTickets < quantity) revert InsufficientTickets();

        uint256 totalCost = uint256(quantity) * raffle.ticketTokenQuantity;
        
        // Transfer tokens first to prevent reentrancy
        IERC20(raffle.ticketToken).transferFrom(msg.sender, address(this), totalCost);

        uint32 ticketsAssigned;
        uint256 i;
        
        // Find available tickets (including refunded ones)
        while (ticketsAssigned < quantity && i < type(uint32).max) {
            if (raffle.ticketOwners[i] == address(0) || raffle.isTicketRefunded[i]) {
                raffle.ticketOwners[i] = msg.sender;
                raffle.userTickets[msg.sender].push(i);
                raffle.isTicketRefunded[i] = false;
                unchecked { ++ticketsAssigned; }
            }
            unchecked { ++i; }
        }
        
        unchecked {
            raffle.availableTickets -= quantity;
            raffle.totalSold += quantity;
        }
        
        emit TicketsPurchased(raffleId, msg.sender, quantity);
    }

    /**
     * @notice Refund a specific ticket
     * @param raffleId ID of the raffle
     * @param ticketId ID of the ticket to refund
     */
    function refundTicket(uint256 raffleId, uint256 ticketId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isActive && !raffle.isNull) revert RaffleNotActive();
        if (raffle.ticketOwners[ticketId] != msg.sender) revert TicketNotOwned();
        if (raffle.isTicketRefunded[ticketId]) revert TicketAlreadyRefunded();

        raffle.isTicketRefunded[ticketId] = true;
        unchecked {
            raffle.availableTickets++;
            raffle.totalSold--;
        }

        IERC20(raffle.ticketToken).transfer(msg.sender, raffle.ticketTokenQuantity);
        emit TicketRefunded(raffleId, msg.sender, ticketId);
    }

    /**
     * @notice Finalize the raffle and determine winners
     * @param raffleId ID of the raffle
     */
    function finalizeRaffle(uint256 raffleId) external {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (block.number < raffle.endBlock) revert RaffleNotEnded();
        if (raffle.isFinalized) revert RaffleAlreadyFinalized();

        if (raffle.totalSold < raffle.minTicketsRequired) {
            raffle.isNull = true;
            raffle.isActive = false;
            raffle.isFinalized = true;
            emit RaffleDeclaredNull(raffleId);
            return;
        }

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp,
            raffle.totalSold
        )));

        _selectWinners(raffleId, randomSeed);
        
        raffle.isActive = false;
        raffle.isFinalized = true;

        emit RaffleFinalized(raffleId, randomSeed);
    }

    /**
     * @notice Internal function to select winners
     * @param raffleId ID of the raffle
     * @param randomSeed Random seed for winner selection
     */
    function _selectWinners(uint256 raffleId, uint256 randomSeed) internal {
        RaffleInfo storage raffle = raffles[raffleId];
        
        uint256[] memory availableTickets = new uint256[](raffle.totalSold);
        uint256 availableIndex;
        
        // Create array of valid tickets
        for (uint256 i = 0; i < type(uint32).max;) {
            if (raffle.ticketOwners[i] != address(0) && !raffle.isTicketRefunded[i]) {
                availableTickets[availableIndex] = i;
                unchecked { ++availableIndex; }
                if (availableIndex == raffle.totalSold) break;
            }
            unchecked { ++i; }
        }

        // Select winners for each pool
        uint256 currentSeed = randomSeed;
        uint256 processedTickets;

        for (uint256 i = 0; i < raffle.ticketDistribution.length;) {
            uint256 winnersCount = raffle.ticketDistribution[i].ticketQuantity;
            
            if (raffle.ticketDistribution[i].fundPercentage > 0) {
                for (uint256 j = 0; j < winnersCount;) {
                    currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, j)));
                    uint256 winnerIndex = processedTickets + (currentSeed % (raffle.totalSold - processedTickets));
                    
                    // Swap and select winner
                    uint256 temp = availableTickets[processedTickets];
                    availableTickets[processedTickets] = availableTickets[winnerIndex];
                    availableTickets[winnerIndex] = temp;
                    
                    raffle.winningTicketsPerPool[i].push(availableTickets[processedTickets]);
                    
                    unchecked { 
                        ++processedTickets;
                        ++j;
                    }
                }
            }
            unchecked { ++i; }
        }
    }

    /**
     * @notice Claim prizes for winning tickets
     * @param raffleId ID of the raffle
     */
    function claimPrize(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isFinalized) revert RaffleNotFinalized();
        if (raffle.isNull) revert RaffleIsNull();
        if (raffle.hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256[] memory userTicketIds = raffle.userTickets[msg.sender];
        if (userTicketIds.length == 0) return;

        uint256 totalPrize;
        uint256 totalPoolFunds = uint256(raffle.totalSold) * raffle.ticketTokenQuantity;

        for (uint256 i = 0; i < userTicketIds.length;) {
            uint256 ticketId = userTicketIds[i];
            
            for (uint256 j = 0; j < raffle.ticketDistribution.length;) {
                if (raffle.ticketDistribution[j].fundPercentage > 0) {
                    if (_isTicketInArray(ticketId, raffle.winningTicketsPerPool[j])) {
                        uint256 prizePerTicket = (totalPoolFunds * raffle.ticketDistribution[j].fundPercentage) / 
                            (100 * raffle.ticketDistribution[j].ticketQuantity);
                        totalPrize += prizePerTicket;
                        break;
                    }
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }

        if (totalPrize > 0) {
            raffle.hasClaimed[msg.sender] = true;
            IERC20(raffle.ticketToken).transfer(msg.sender, totalPrize);
            emit PrizeClaimed(raffleId, msg.sender, totalPrize);
        }
    }

    /**
     * @notice Claim refund for null raffle
     * @param raffleId ID of the raffle
     */
    function claimRefund(uint256 raffleId) external nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isNull) revert RaffleIsNull();
        if (raffle.hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256[] memory userTicketIds = raffle.userTickets[msg.sender];
        if (userTicketIds.length == 0) return;

        uint256 refundAmount;
        for (uint256 i = 0; i < userTicketIds.length;) {
            if (!raffle.isTicketRefunded[userTicketIds[i]]) {
                refundAmount += raffle.ticketTokenQuantity;
                raffle.isTicketRefunded[userTicketIds[i]] = true;
            }
            unchecked { ++i; }
        }

        if (refundAmount > 0) {
            raffle.hasClaimed[msg.sender] = true;
            IERC20(raffle.ticketToken).transfer(msg.sender, refundAmount);
        }
    }

    /**
     * @notice Check if a ticket is in an array
     * @param ticket Ticket ID to check
     * @param array Array of ticket IDs
     */
    function _isTicketInArray(uint256 ticket, uint256[] storage array) internal view returns (bool) {
        for (uint256 i = 0; i < array.length;) {
            if (array[i] == ticket) return true;
            unchecked { ++i; }
        }
        return false;
    }

    // View functions
    function getUserTickets(uint256 raffleId, address user) external view returns (uint256[] memory) {
        return raffles[raffleId].userTickets[user];
    }

    function getWinningTicketsForPool(uint256 raffleId, uint256 poolIndex) external view returns (uint256[] memory) {
        return raffles[raffleId].winningTicketsPerPool[poolIndex];
    }

    function getRaffleInfo(uint256 raffleId) external view returns (
        address ticketToken,
        uint96 ticketTokenQuantity,
        uint32 endBlock,
        uint32 minTicketsRequired,
        uint32 totalSold,
        uint32 availableTickets,
        bool isActive,
        bool isFinalized,
        bool isNull
    ) {
        RaffleInfo storage raffle = raffles[raffleId];
        return (
            raffle.ticketToken,
            raffle.ticketTokenQuantity,
            raffle.endBlock,
            raffle.minTicketsRequired,
            raffle.totalSold,
            raffle.availableTickets,
            raffle.isActive,
            raffle.isFinalized,
            raffle.isNull
        );
    }
}