// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITicketPricing.sol";

contract LogisticPricing is ITicketPricing {
    // k determines steepness of the curve
    uint256 private constant k = 4;
    uint256 private constant PRECISION = 1e6;

    function calculatePrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold
    ) external pure returns (uint256) {
        if (ticketsSold >= totalTickets) return basePrice * 2;
        
        // Calculate x value between -6 and 6 based on tickets sold
        uint256 x = (uint256(ticketsSold) * 12 / uint256(totalTickets)) - 6;
        
        // Logistic function: basePrice * (1 + 1/(1 + e^(-kx)))
        uint256 multiplier = PRECISION + _logisticFunction(x);
        return (basePrice * multiplier) / PRECISION;
    }

    function calculateBatchPrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold,
        uint32 quantity
    ) external pure returns (uint256) {
        uint256 totalPrice;
        
        for (uint32 i = 0; i < quantity;) {
            if (ticketsSold + i >= totalTickets) {
                // For remaining tickets, use maximum price
                totalPrice += basePrice * 2;
            } else {
                uint256 x = ((uint256(ticketsSold + i) * 12) / uint256(totalTickets)) - 6;
                uint256 multiplier = PRECISION + _logisticFunction(x);
                totalPrice += (basePrice * multiplier) / PRECISION;
            }
            unchecked { ++i; }
        }
        
        return totalPrice;
    }

    function _logisticFunction(uint256 x) private pure returns (uint256) {
        // Approximate e^(-kx) using a Taylor series
        uint256 kx = -k * x;
        uint256 exp = PRECISION;
        uint256 term = PRECISION;
        
        for (uint256 i = 1; i <= 4; i++) {
            term = (term * kx) / uint256(i * PRECISION);
            exp += term;
        }

        return uint256(PRECISION * PRECISION / (PRECISION + uint256(exp)));
    }
}