// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RaffleStorage.sol";
import "../interfaces/IRaffle.sol";
import "../libraries/RaffleLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/ITicketPricing.sol";
import { IEntropyConsumer } from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

abstract contract BaseRaffle is IRaffle, IEntropyConsumer, RaffleStorage, ReentrancyGuard, Ownable {
    ITicketPricing public ticketPricing;
    IEntropy public entropy;
    uint256 public feePercentage;
    address public feeCollector;

    modifier updateRaffleState(uint256 raffleId) {
        RaffleInfo storage raffle = raffles[raffleId];
        if (raffle.isActive && block.number >= raffle.endBlock) {
            raffle.isActive = false;
            emit RaffleStateUpdated(raffleId, false);
            
            if (raffle.ticketsMinted - raffle.ticketsRefunded < raffle.minTicketsRequired) {
                raffle.isNull = true;
                emit RaffleDeclaredNull(raffleId);
            }
        }
        _;
    }

    constructor(
        address entropyAddress,
        address _ticketPricing,
        address _feeCollector,
        uint256 _feePercentage
    ) Ownable(msg.sender) {
        require(_feePercentage <= 1000, "Fee cannot exceed 10%");
        entropy = IEntropy(entropyAddress);
        ticketPricing = ITicketPricing(_ticketPricing);
        feeCollector = _feeCollector;
        feePercentage = _feePercentage;
    }

    function createRaffle(
        uint32 totalTickets,
        address ticketToken,
        uint96 ticketTokenQuantity,
        TicketDistribution[] calldata distribution,
        uint32 duration,
        uint32 minTicketsRequired
    ) external virtual {
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

        uint256 raffleId = raffleCounter++;
        RaffleInfo storage raffle = raffles[raffleId];

        raffle.raffleId = raffleId;
        raffle.ticketToken = ticketToken;
        raffle.ticketTokenQuantity = ticketTokenQuantity;
        raffle.totalTickets = totalTickets;
        raffle.ticketsAvailable = totalTickets;
        raffle.endBlock = uint32(block.number) + duration;
        raffle.minTicketsRequired = minTicketsRequired;
        raffle.isActive = true;

        for (uint256 i = 0; i < distribution.length;) {
            raffle.ticketDistribution.push(distribution[i]);
            unchecked { ++i; }
        }

        emit RaffleCreated(raffleId, msg.sender, totalTickets);
    }

    function claimPrize(uint256 raffleId) 
        external 
        virtual 
        nonReentrant 
        updateRaffleState(raffleId) 
    {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isFinalized) revert RaffleNotFinalized();
        if (raffle.isNull) revert RaffleIsNull();
        if (raffle.hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256 prize = RaffleLib.calculatePrize(
            raffle.userTickets[msg.sender],
            raffle.ticketOwnersAndPrizes
        );

        if (prize > 0) {
            raffle.hasClaimed[msg.sender] = true;
            IERC20(raffle.ticketToken).transfer(msg.sender, prize);
            emit PrizeClaimed(raffleId, msg.sender, prize);
        }
    }

    function claimRefund(uint256 raffleId) external virtual nonReentrant {
        RaffleInfo storage raffle = raffles[raffleId];
        
        if (!raffle.isNull) revert RaffleIsNull();
        if (raffle.hasClaimed[msg.sender]) revert AlreadyClaimed();

        uint256[] memory userTicketIds = raffle.userTickets[msg.sender];
        if (userTicketIds.length == 0) return;

        uint256 refundAmount;
        for (uint256 i = 0; i < userTicketIds.length;) {
            IRaffle.PackedTicketInfo memory ticketInfo = raffle.ticketOwnersAndPrizes[userTicketIds[i]];
            if (ticketInfo.owner == msg.sender && !raffle.isTicketRefunded[userTicketIds[i]]) {
                refundAmount += ticketInfo.purchasePrice;
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

        // Update the total pool token quantity
        raffle.totalPoolTokenQuantity -= ticketInfo.purchasePrice;

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
        uint256 feeAmount = (raffle.totalPoolTokenQuantity * feePercentage) / 10000;
        raffle.totalPoolTokenQuantity -= feeAmount;

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

        // Calculate prize per winner = fund percertage (%) * total pool token quantity / total tickets for pool
        uint256 poolPrize = Math.mulDiv(raffle.totalPoolTokenQuantity, dist.fundPercentage, 100);
        uint256 prizePerWinner = poolPrize / dist.ticketQuantity;

        emit PoolPrizeCreated(raffle.raffleId, poolIndex, poolPrize, prizePerWinner);
        
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

    function entropyCallback(
        uint64 sequenceNumber,
        address ,
        bytes32 randomNumber
    ) internal override {
        uint256 raffleId = sequenceNumberToRaffleId[sequenceNumber];
        RaffleInfo storage raffle = raffles[raffleId];

        raffle.randomSeed = uint256(randomNumber);
        raffle.isFinalized = true;
        emit RaffleFinalized(raffleId, raffle.randomSeed);
    }

    function getEntropy() internal view override returns (address) {
        return address(entropy);
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

    // Add function to update pricing contract
    function setTicketPricing(address _ticketPricing) external onlyOwner {
        require(_ticketPricing != address(0), "Invalid address");
        ticketPricing = ITicketPricing(_ticketPricing);
    }

    // Abstract function to be implemented by specific implementations
    function _assignTickets(
        uint256 raffleId,
        address buyer,
        uint32 quantity,
        uint256 totalCost,
        uint256[] memory pricePerTicket
    ) internal virtual;
} 