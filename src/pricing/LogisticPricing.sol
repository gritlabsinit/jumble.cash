// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITicketPricing.sol";

contract LogisticPricing is ITicketPricing {
    // k determines steepness of the curve
    uint256 private constant k = 4;
    uint256 private constant PRECISION = 1e6;
    uint256 private constant MAX_MULTIPLIER = 2 * PRECISION; // Maximum 2x price increase

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
        if (ticketsSold >= totalTickets) {
            return basePrice * 2 * quantity;
        }

        // For efficiency in batch calculations, use average price for the batch
        uint256 midPoint = ticketsSold + (quantity / 2);
        if (midPoint >= totalTickets) {
            midPoint = totalTickets - 1;
        }

        // Calculate x value for the midpoint
        uint256 x = (uint256(midPoint) * 12 / uint256(totalTickets)) - 6;
        uint256 multiplier = PRECISION + _logisticFunction(x);
        
        // Apply the average price to all tickets in the batch
        return (basePrice * multiplier * quantity) / PRECISION;
    }

    function _logisticFunction(uint256 x) private pure returns (uint256) {
        // Approximate e^(-kx) using a Taylor series
        int256 kx = -int256(k * x);
        int256 exp = int256(PRECISION);
        int256 term = int256(PRECISION);
        
        for (uint256 i = 1; i <= 4; i++) {
            term = (term * kx) / int256(i * PRECISION);
            exp += term;
        }

        // Ensure exp is positive to avoid division by zero
        if (exp <= 0) {
            return MAX_MULTIPLIER - PRECISION;
        }

        uint256 denominator = uint256(exp) + PRECISION;
        uint256 result = (PRECISION * PRECISION) / denominator;

        // Cap the result to avoid overflow
        return result > (MAX_MULTIPLIER - PRECISION) ? 
            (MAX_MULTIPLIER - PRECISION) : result;
    }

    // View functions for testing and verification
    function getLogisticMultiplier(
        uint32 totalTickets,
        uint32 ticketsSold
    ) external pure returns (uint256) {
        if (ticketsSold >= totalTickets) return 2 * PRECISION;
        
        uint256 x = (uint256(ticketsSold) * 12 / uint256(totalTickets)) - 6;
        return PRECISION + _logisticFunction(x);
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }
}