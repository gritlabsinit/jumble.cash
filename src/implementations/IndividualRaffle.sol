// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../base/BaseRaffle.sol";

contract IndividualRaffle is BaseRaffle {
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

        IERC20(raffle.ticketToken).transferFrom(msg.sender, address(this), totalCost);

        raffle.totalPoolTokenQuantity += totalCost;
        _assignTickets(raffleId, msg.sender, quantity, totalCost, prices);
        
        emit TicketsPurchased(raffleId, msg.sender, quantity);
    }

    function _assignTickets(
        uint256 raffleId,
        address buyer,
        uint32 quantity,
        uint256 ,
        uint256[] memory pricePerTicket
    ) internal override {
        RaffleInfo storage raffle = raffles[raffleId];
        uint32 assigned;

        // Assign refunded tickets first
        while (assigned < quantity && raffle.refundedTicketIds.length > 0) {
            uint256 ticketId = raffle.refundedTicketIds[raffle.refundedTicketIds.length - 1];
            raffle.ticketOwnersAndPrizes[ticketId] = PackedTicketInfo({
                owner: buyer,
                prizeShare: 0,
                purchasePrice: pricePerTicket[assigned]
            });
            raffle.userTickets[buyer].push(ticketId);
            raffle.refundedTicketIds.pop();
            unchecked {
                ++assigned;
                --raffle.ticketsRefunded;
            }
        }

        // Assign new tickets if needed
        uint256 currentTicketId = raffle.ticketsMinted - raffle.ticketsRefunded;
        while (assigned < quantity) {
            raffle.ticketOwnersAndPrizes[currentTicketId] = PackedTicketInfo({
                owner: buyer,
                prizeShare: 0,
                purchasePrice: pricePerTicket[assigned]
            });
            raffle.userTickets[buyer].push(currentTicketId);
            unchecked {
                ++assigned;
                ++currentTicketId;
            }
        }

        require(assigned == quantity, "Failed to assign all tickets");
        raffle.ticketsAvailable -= quantity;
    }

    function getTicketPrice(uint256 raffleId, uint32 quantity) external view returns (uint256) {
        RaffleInfo storage raffle = raffles[raffleId];
        return ticketPricing.calculatePrice(
            raffle.ticketTokenQuantity,
            raffle.totalTickets,
            raffle.ticketsMinted - raffle.ticketsRefunded + quantity - 1
        );
    }

    function getSimulatedTicketPrice(uint256 ticketTokenQuantity, uint32 totalTickets, uint32 ticketsMinted, uint32 quantity) external view returns (uint256) {
        return ticketPricing.calculateBatchPrice(
            ticketTokenQuantity,
            totalTickets,
            ticketsMinted,
            quantity
        );
    }
}       