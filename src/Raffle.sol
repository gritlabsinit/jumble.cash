// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IEntropyConsumer } from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import "./interfaces/ITicketPricing.sol";

/**
 * @title Raffle
 * @notice A gas-optimized raffle contract with refund functionality and minimum ticket requirements
 */
contract Raffle is IEntropyConsumer, ReentrancyGuard, Ownable {
    // Add constructor to initialize Ownable
    constructor(
        address entropyAddress,
        address _feeCollector,
        uint256 _feePercentage,
        address _ticketPricing
    ) Ownable(msg.sender) {
        entropy = IEntropy(entropyAddress);
        feeCollector = _feeCollector;
        require(_feePercentage <= 1000, "Fee cannot exceed 10%"); // Max 10% fee
        feePercentage = _feePercentage;
        ticketPricing = ITicketPricing(_ticketPricing);
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

    struct TicketDistribution {
        uint96 fundPercentage; // Using uint96 to pack with ticketQuantity
        uint96 ticketQuantity;
    }

    struct RaffleInfo {
        address ticketToken;
        uint96 ticketTokenQuantity;

        uint32 totalTickets; // N: total tickets possible
        uint32 ticketsMinted; // Tm: number of new tickets minted
        uint32 ticketsRefunded; // Tr: number of tickets refunded
        uint32 ticketsAvailable; // Ta: number of tickets available for sale
        
        uint64 sequenceNumber; // N: sequence number for entropy request
        uint256 randomSeed; // N: random seed for winner selection

        uint256 feeCollected; // N: fee percentage to be collected
        uint32 minTicketsRequired; // Tmin: minimum tickets required to be sold for raffle to be valid
        uint32 endBlock; // N: block number when raffle ends

        bool isActive; // N: raffle is active
        bool isFinalized; // N: raffle is finalized
        bool isNull; // N: raffle is null

        // create a mapping of ticketIdx to the owner and the percentage of the pool it is eligible for

        // Packed into single slots above
        mapping(address => uint256[]) userTickets;
        mapping(uint256 => PackedTicketInfo) ticketOwnersAndPrizes;
        mapping(address => bool) hasClaimed;
        mapping(uint256 => bool) isTicketRefunded;
        TicketDistribution[] ticketDistribution;
        mapping(uint256 => uint256[]) winningTicketsPerPool;
        uint32[] refundedTicketIds;
    }

    // New struct to pack ticket info efficiently
    struct PackedTicketInfo {
        address owner;      // 160 bits
        uint96 prizeShare;  // 96 bits (percentage of total pool * 1e6 for precision)
        uint256 purchasePrice; // Store the price at which ticket was purchased
    }

    // State variables
    mapping(uint256 => RaffleInfo) public raffles;
    mapping(uint256 => uint256) public sequenceNumberToRaffleId;
    uint256 public raffleCounter;
    IEntropy public entropy;
    uint256 public feePercentage; // In basis points (e.g., 250 = 2.50%)
    address public feeCollector;
    ITicketPricing public ticketPricing;

    // Events
    event RaffleCreated(uint256 indexed raffleId, address creator, uint256 totalTickets);
    event TicketsPurchased(uint256 indexed raffleId, address indexed buyer, uint256 quantity);
    event TicketRefunded(uint256 indexed raffleId, address indexed user, uint256 ticketId);
    event SequenceNumberRequested(uint256 indexed raffleId, uint64 sequenceNumber);
    event RaffleFinalized(uint256 indexed raffleId, uint256 randomSeed);
    event RaffleDeclaredNull(uint256 indexed raffleId);
    event PrizeClaimed(uint256 indexed raffleId, address indexed winner, uint256 amount);
    event FeeCollected(uint256 indexed raffleId, uint256 amount);
    event WinnersSelected(uint256 indexed raffleId, uint32 validTickets);
    event RaffleStateUpdated(uint256 indexed raffleId, bool isActive);

    // Add modifier to check and update raffle state
    modifier updateRaffleState(uint256 raffleId) {
        RaffleInfo storage raffle = raffles[raffleId];
        
        // Check if raffle needs to be deactivated
        if (raffle.isActive && block.number >= raffle.endBlock) {
            raffle.isActive = false;
            emit RaffleStateUpdated(raffleId, false);
            
            // If minimum tickets weren't sold, mark as null
            if (raffle.ticketsMinted - raffle.ticketsRefunded < raffle.minTicketsRequired) {
                raffle.isNull = true;
                emit RaffleDeclaredNull(raffleId);
            }
        }
        _;
    }

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

        raffle.totalTickets = totalTickets;
        raffle.ticketsAvailable = totalTickets;
        
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
    function buyTickets(uint256 raffleId, uint32 quantity) 
        external 
        nonReentrant 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isActive) revert RaffleNotActive();
        if (raffle.ticketsAvailable < quantity) revert InsufficientTickets();
        if (quantity == 0) revert InvalidTicketId();

        uint256 totalCost = 0;
        uint256[] memory prices = new uint256[](quantity);
        
        for (uint32 i = 0; i < quantity;) {
            uint256 price = ticketPricing.calculatePrice(
                raffle.ticketTokenQuantity,
                raffle.totalTickets,
                raffle.ticketsMinted - raffle.ticketsRefunded + i
            );
            prices[i] = price;
            totalCost += price;
            unchecked { ++i; }
        }

        IERC20(raffle.ticketToken).transferFrom(
            msg.sender, 
            address(this), 
            totalCost
        );

        _assignTicketsIndividual(raffle, msg.sender, quantity, prices);
        
        emit TicketsPurchased(raffleId, msg.sender, quantity);
    }

    /**
     * @notice Batch purchase tickets for a raffle
     * @dev This is a batch version of the buyTickets function with approximate pricing
     * @param raffleId ID of the raffle
     * @param quantity Number of tickets to purchase
     */
    function buyTicketsBatch(uint256 raffleId, uint32 quantity) 
        external 
        nonReentrant 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isActive) revert RaffleNotActive();
        if (raffle.ticketsAvailable < quantity) revert InsufficientTickets();
        if (quantity == 0) revert InvalidTicketId();

        uint256 totalCost = ticketPricing.calculateBatchPrice(
            raffle.ticketTokenQuantity,
            raffle.totalTickets,
            raffle.ticketsMinted - raffle.ticketsRefunded,
            quantity
        );

        uint256 pricePerTicket = totalCost / quantity;

        IERC20(raffle.ticketToken).transferFrom(
            msg.sender, 
            address(this), 
            totalCost
        );

        _assignTicketsBatch(raffle, msg.sender, quantity, pricePerTicket);
        
        emit TicketsPurchased(raffleId, msg.sender, quantity);
    }

    // Split into two assignment functions
    function _assignTicketsIndividual(
        RaffleInfo storage raffle, 
        address buyer, 
        uint32 quantity, 
        uint256[] memory prices
    ) private {
        uint32 assigned;
        
        // Assign refunded tickets first
        while (assigned < quantity && raffle.ticketsRefunded > 0) {
            uint256 ticketId = raffle.refundedTicketIds[raffle.ticketsRefunded - 1];
            raffle.ticketOwnersAndPrizes[ticketId] = PackedTicketInfo({
                owner: buyer,
                prizeShare: 0,
                purchasePrice: prices[assigned]
            });
            raffle.userTickets[buyer].push(ticketId);
            raffle.refundedTicketIds.pop();
            unchecked {
                ++assigned;
                --raffle.ticketsRefunded;
            }
        }

        // Assign new tickets if needed
        uint256 currentId = raffle.ticketsMinted;
        while (assigned < quantity && currentId < raffle.totalTickets) {
            if (raffle.ticketOwnersAndPrizes[currentId].owner == address(0)) {
                raffle.ticketOwnersAndPrizes[currentId] = PackedTicketInfo({
                    owner: buyer,
                    prizeShare: 0,
                    purchasePrice: prices[assigned]
                });
                raffle.userTickets[buyer].push(currentId);
                unchecked {
                    ++assigned;
                    ++raffle.ticketsMinted;
                }
            }
            unchecked { ++currentId; }
        }

        require(assigned == quantity, "Failed to assign all tickets");
        raffle.ticketsAvailable -= quantity;
    }

    function _assignTicketsBatch(
        RaffleInfo storage raffle, 
        address buyer, 
        uint32 quantity, 
        uint256 pricePerTicket
    ) private {
        uint32 assigned;
        
        // Assign refunded tickets first
        while (assigned < quantity && raffle.ticketsRefunded > 0) {
            uint256 ticketId = raffle.refundedTicketIds[raffle.ticketsRefunded - 1];
            raffle.ticketOwnersAndPrizes[ticketId] = PackedTicketInfo({
                owner: buyer,
                prizeShare: 0,
                purchasePrice: pricePerTicket
            });
            raffle.userTickets[buyer].push(ticketId);
            raffle.refundedTicketIds.pop();
            unchecked {
                ++assigned;
                --raffle.ticketsRefunded;
            }
        }

        // Assign new tickets if needed
        uint256 currentId = raffle.ticketsMinted;
        while (assigned < quantity && currentId < raffle.totalTickets) {
            if (raffle.ticketOwnersAndPrizes[currentId].owner == address(0)) {
                raffle.ticketOwnersAndPrizes[currentId] = PackedTicketInfo({
                    owner: buyer,
                    prizeShare: 0,
                    purchasePrice: pricePerTicket
                });
                raffle.userTickets[buyer].push(currentId);
                unchecked {
                    ++assigned;
                    ++raffle.ticketsMinted;
                }
            }
            unchecked { ++currentId; }
        }

        require(assigned == quantity, "Failed to assign all tickets");
        raffle.ticketsAvailable -= quantity;
    }

    /**
     * @notice Refund a specific ticket
     * @param raffleId ID of the raffle
     * @param ticketId ID of the ticket to refund
     */
    function refundTicket(uint256 raffleId, uint32 ticketId) 
        external 
        nonReentrant 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];        
        if (!raffle.isActive) revert RaffleNotActive();
        
        PackedTicketInfo memory ticketInfo = raffle.ticketOwnersAndPrizes[ticketId];
        if (ticketInfo.owner != msg.sender) revert TicketNotOwned();

        // add the ticket id to the refunded ticket ids array
        raffle.refundedTicketIds.push(ticketId);
        raffle.ticketOwnersAndPrizes[ticketId] = PackedTicketInfo({
            owner: address(0),
            prizeShare: 0,
            purchasePrice: 0
        });

        unchecked {
            raffle.ticketsRefunded++;
            raffle.ticketsAvailable++;
        }

        // Refund the original purchase price
        IERC20(raffle.ticketToken).transfer(msg.sender, ticketInfo.purchasePrice);
        emit TicketRefunded(raffleId, msg.sender, ticketId);
    }

    /**
     * @notice Finalize the raffle and determine winners
     * @param raffleId ID of the raffle
     */
    function finalizeRaffle(uint256 raffleId) 
        external 
        payable 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (block.number < raffle.endBlock) revert RaffleNotEnded();
        if (raffle.isFinalized) revert RaffleAlreadyFinalized();

        uint32 _ticketsSold = raffle.ticketsMinted - raffle.ticketsRefunded;
        if (_ticketsSold < raffle.minTicketsRequired) {
            raffle.isNull = true;
            raffle.isActive = false;
            raffle.isFinalized = true;
            emit RaffleDeclaredNull(raffleId);
            return;
        }

        // Calculate and transfer fees
        uint256 totalPoolAmount = uint256(_ticketsSold) * raffle.ticketTokenQuantity;
        uint256 feeAmount = (totalPoolAmount * feePercentage) / 10000;
        
        if (feeAmount > 0) {
            IERC20(raffle.ticketToken).transfer(feeCollector, feeAmount);
            raffle.feeCollected = feeAmount; // Store fee amount for reference
        }

        // Request random number
        address entropyProvider = entropy.getDefaultProvider();
        uint256 fee = entropy.getFee(entropyProvider);
 
        uint64 sequenceNumber = entropy.requestWithCallback{ value: fee }(
            entropyProvider,
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        raffle.sequenceNumber = sequenceNumber;
        sequenceNumberToRaffleId[sequenceNumber] = raffleId;

        raffle.isActive = false;
        emit SequenceNumberRequested(raffleId, sequenceNumber);
    }

    
    /**
     * @notice Internal function to select winners
     * @param raffleId ID of the raffle
     */
    function selectWinners(uint256 raffleId) 
        public 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        if (raffle.isActive) revert RaffleNotEnded();
        require(raffle.isFinalized && !raffle.isNull, "Invalid raffle state");

        uint32 validTickets = raffle.ticketsMinted - raffle.ticketsRefunded;
        _selectWinnersForPools(raffle, validTickets);

        emit WinnersSelected(raffleId, validTickets);
    }

    function _selectWinnersForPools(RaffleInfo storage raffle, uint32 validTickets) private {
        uint256[] memory tickets = new uint256[](validTickets);
        uint256 idx;
        
        // Fill valid tickets array
        for (uint256 i; i < raffle.ticketsMinted && idx < validTickets;) {
            if (raffle.ticketOwnersAndPrizes[i].owner != address(0)) {
                tickets[idx++] = i;
            }
            unchecked { ++i; }
        }

        // Select winners
        uint256 seed = raffle.randomSeed;
        uint256 processed;

        for (uint256 i; i < raffle.ticketDistribution.length;) {
            TicketDistribution memory dist = raffle.ticketDistribution[i];
            if (dist.ticketQuantity > 0 && dist.fundPercentage > 0) {
                uint256 winners = dist.ticketQuantity > (validTickets - processed) ? 
                                (validTickets - processed) : 
                                dist.ticketQuantity;
                
                _selectPoolWinners(raffle, i, tickets, processed, winners, seed);
                processed += winners;
            }
            if (processed >= validTickets) break;
            unchecked { ++i; }
        }
    }

    function _selectPoolWinners(
        RaffleInfo storage raffle,
        uint256 poolIndex,
        uint256[] memory tickets,
        uint256 startIndex,
        uint256 count,
        uint256 seed
    ) private {
        TicketDistribution memory dist = raffle.ticketDistribution[poolIndex];
        uint256 prizePerWinner = (dist.fundPercentage * 1e6) / dist.ticketQuantity; // Scale by 1e6 for precision
        
        for (uint256 i; i < count;) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint256 winnerIdx = startIndex + (seed % (tickets.length - startIndex));
            
            // Swap winner to current position
            (tickets[startIndex], tickets[winnerIdx]) = (tickets[winnerIdx], tickets[startIndex]);
            uint256 winningTicket = tickets[startIndex];
            
            // Store prize share directly with ticket
            PackedTicketInfo storage ticketInfo = raffle.ticketOwnersAndPrizes[winningTicket];
            ticketInfo.prizeShare = uint96(prizePerWinner); // Prize share in basis points * 1e6
            
            unchecked {
                ++startIndex;
                ++i;
            }
        }
    }

    /**
     * @notice Claim prizes for winning tickets
     * @param raffleId ID of the raffle
     */
    function claimPrize(uint256 raffleId) 
        external 
        nonReentrant 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isFinalized) revert RaffleNotFinalized();
        if (raffle.isNull) revert RaffleIsNull();
        if (raffle.hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256 prize = _calculatePrize(raffle, msg.sender);
        if (prize == 0) return;

        raffle.hasClaimed[msg.sender] = true;
        IERC20(raffle.ticketToken).transfer(msg.sender, prize);
        emit PrizeClaimed(raffleId, msg.sender, prize);
    }

    function _calculatePrize(RaffleInfo storage raffle, address user) private view returns (uint256) {
        uint256[] memory userTickets = raffle.userTickets[user];
        if (userTickets.length == 0) return 0;

        uint256 totalPool = uint256(raffle.ticketsMinted - raffle.ticketsRefunded) * 
                           raffle.ticketTokenQuantity - 
                           raffle.feeCollected;
        uint256 prize;

        // Calculate prize based on stored prize shares
        for (uint256 i; i < userTickets.length;) {
            uint256 ticketId = userTickets[i];
            PackedTicketInfo memory ticketInfo = raffle.ticketOwnersAndPrizes[ticketId];
            
            if (ticketInfo.prizeShare > 0) {
                unchecked {
                    prize += (totalPool * ticketInfo.prizeShare) / 1e8; // Adjust for precision
                }
            }
            unchecked { ++i; }
        }
        
        return prize;
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
            if (raffle.ticketOwnersAndPrizes[userTicketIds[i]].owner == msg.sender && !raffle.isTicketRefunded[userTicketIds[i]]) {
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
            raffle.minTicketsRequired,
            raffle.ticketsRefunded,
            raffle.ticketsMinted,
            raffle.ticketsAvailable,
            raffle.isActive,
            raffle.isFinalized,
            raffle.isNull
        );
    }

    /** 
     * @param sequenceNumber The sequence number of the request.
     * @param provider The address of the provider that generated the random number. If your app uses multiple providers, you can use this argument to distinguish which one is calling the app back.
     * @param randomNumber The generated random number.
     **/
    function entropyCallback(
        uint64 sequenceNumber,
        address provider,
        bytes32 randomNumber
    ) internal override {
        uint256 raffleId = sequenceNumberToRaffleId[sequenceNumber];
        RaffleInfo storage raffle = raffles[raffleId];

        raffle.randomSeed = uint256(randomNumber);
        
        raffle.isFinalized = true;
        emit RaffleFinalized(raffleId, raffle.randomSeed);
    }

    // Add fee management functions
    function setFeeCollector(address _feeCollector) external onlyOwner {
        if (_feeCollector == address(0)) revert ZeroAddress();
        feeCollector = _feeCollector;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "Fee cannot exceed 10%");
        feePercentage = _feePercentage;
    }

    // getters
    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    function getFeePercentage() external view returns (uint256) {
        return feePercentage;
    }

    function getSequenceFees() external view returns (uint256) {
        return entropy.getFee(entropy.getDefaultProvider());
    }

    // This method is required by the IEntropyConsumer interface.
    // It returns the address of the entropy contract which will call the callback.
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    // This method is used to get the owner and prize share of a ticket
    // It is used for testing purposes
    function getTicketInfo(uint256 raffleId, uint256 ticketId) external view returns (
        address owner, 
        uint96 prizeShare,
        uint256 purchasePrice
    ) {
        RaffleInfo storage raffle = raffles[raffleId];
        PackedTicketInfo memory ticketInfo = raffle.ticketOwnersAndPrizes[ticketId];
        return (ticketInfo.owner, ticketInfo.prizeShare, ticketInfo.purchasePrice);
    }

    // Optional: Add function to manually check/update state
    function checkRaffleState(uint256 raffleId) external updateRaffleState(raffleId) {
        // This function only executes the modifier
        // Useful for external contracts that need to ensure state is current
    }

    // Add function to update pricing contract
    function setTicketPricing(address _ticketPricing) external onlyOwner {
        require(_ticketPricing != address(0), "Invalid address");
        ticketPricing = ITicketPricing(_ticketPricing);
    }

}
