// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../base/BaseRaffle.sol";

contract BatchRaffle is BaseRaffle {
    constructor(
        address entropyAddress,
        address _ticketPricing,
        address _feeCollector,
        uint256 _feePercentage
    ) BaseRaffle(entropyAddress, _ticketPricing, _feeCollector, _feePercentage) {}

    function buyTickets(uint256 raffleId, uint32 quantity) 
        external 
        override 
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

        IERC20(raffle.ticketToken).transferFrom(msg.sender, address(this), totalCost);
        
        raffle.totalPoolTokenQuantity += totalCost;
        uint256[] memory pricePerTicket = new uint256[](0);
        _assignTickets(raffleId, msg.sender, quantity, totalCost, pricePerTicket);
        
        emit TicketsPurchased(raffleId, msg.sender, quantity);
    }

    function _assignTickets(
        uint256 raffleId,
        address buyer,
        uint32 quantity,
        uint256 totalCost,
        uint256[] memory
    ) internal override {
        RaffleInfo storage raffle = raffles[raffleId];
        uint32 assigned;
        uint256 pricePerTicket = totalCost / quantity;
            
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
        uint256 currentTicketId = raffle.ticketsMinted;
        while (assigned < quantity && currentTicketId < raffle.totalTickets) {
            if (raffle.ticketOwnersAndPrizes[currentTicketId].owner == address(0)) {
                raffle.ticketOwnersAndPrizes[currentTicketId] = PackedTicketInfo({
                    owner: buyer,
                    prizeShare: 0,
                    purchasePrice: pricePerTicket
                });
                raffle.userTickets[buyer].push(currentTicketId);
                unchecked {
                    ++assigned;
                    ++raffle.ticketsMinted;
                }
            }
            unchecked { ++currentTicketId; }
        }

        require(assigned == quantity, "Failed to assign all tickets");
        raffle.ticketsAvailable -= quantity;
    }

    function getTicketPrice(uint256 raffleId, uint32 quantity) external view returns (uint256) {
        RaffleInfo storage raffle = raffles[raffleId];
        return ticketPricing.calculateBatchPrice(
            raffle.ticketTokenQuantity,
            raffle.totalTickets,
            raffle.ticketsMinted - raffle.ticketsRefunded,
            quantity
        );
    }
} 