// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITicketPricing.sol";

contract LogisticPricing is ITicketPricing {
    uint256 private constant PRECISION = 1e6;
    uint256 private constant MIN_LOWER_SUPPLY_PERCENT = 30;

    /**
     * @dev Calculates the price for a given supply using the sigmoid function:
     * P(S) = Pmin + (Pmax - Pmin) * (1 / (1 + e^(-k(S - Smax/2)))
     * @param basePrice The base price of the ticket
     * @param totalTickets The total number of tickets
     * @param ticketsSold The number of tickets sold
     * @return price The price of the ticket
     */
    function calculatePrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold
    ) public pure override returns (uint256 price)  {
        require(ticketsSold <= totalTickets, "Supply exceeds total");
        // Limit base price to prevent overflow when doubling
        require(basePrice <= type(uint256).max / (3 * PRECISION), "Base price too large");
        
        // Return 2x price at full supply
        if (ticketsSold == totalTickets) {
            return basePrice * 2;
        }
        
        // Calculate S - Smax/2
        // int256 sMid = int256(uint256(ticketsSold)) - int256(uint256(totalTickets) / 2);
        
        // Calculate -k(S - Smax/2)
        // int256 k = int256(calculateK(totalTickets));
        // int256 exponent = -1 * k * sMid / int256(PRECISION);


        // Safe position calculation for large numbers
        uint256 scaledPosition = uint256(ticketsSold) * 8;
        require(scaledPosition <= type(uint256).max / PRECISION, "Position overflow");
        
        int256 exponent = (int256(scaledPosition * PRECISION) / int256(uint256(totalTickets))) - int256(4 * PRECISION);
        
        // Calculate e^(-k(S - Smax/2))
        uint256 expValue = _exp(uint256(abs(exponent)));
        if (exponent > 0) {
            require(expValue > 0, "Exp value overflow");
            expValue = (PRECISION * PRECISION) / expValue;
        }
        
        // Calculate 1 / (1 + e^(-k(S - Smax/2)))
        require(expValue <= type(uint256).max - PRECISION, "Logistic overflow");
        uint256 logisticValue = (PRECISION * PRECISION) / (PRECISION + expValue);

        // Ensure smooth progression
        uint256 minValue = PRECISION / 20;    // 5% minimum
        uint256 maxValue = PRECISION;         // 100% maximum
        
        if (logisticValue < minValue) {
            logisticValue = minValue;
        } else if (logisticValue > maxValue) {
            logisticValue = maxValue;
        }

        
        // Scale sigmoid to range from 1.0 to 2.0
        // Safe price calculation
        uint256 premium = (basePrice * logisticValue) / PRECISION;
        require(premium <= basePrice, "Premium overflow");
        price = basePrice + premium;
    }
    
    function calculateBatchPrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold,
        uint32 quantity
    ) public pure returns (uint256 price) {
        uint256 totalCost = 0;
        for (uint32 i = 0; i < quantity; i++) {
            totalCost += calculatePrice(basePrice, totalTickets, ticketsSold + i);
        }
        return totalCost;
    }

    /**
     * @dev Calculates e^x using Taylor series approximation
     * @param x The exponent (scaled by SCALE)
     * @return The result (scaled by SCALE)
     */
    function _exp(uint256 x) internal pure returns (uint256) {
        // If x is large, return max uint256 to avoid overflow
        if (x > 50 * PRECISION) {
            return type(uint256).max;
        }
        
        uint256 result = PRECISION;
        uint256 term = PRECISION;
        
        for (uint256 i = 1; i <= 25; i++) {
            // Check for potential overflow before multiplication
            // require(term <= type(uint256).max / x, "Exp term overflow");
            term = (term * x) / (i * PRECISION);

            // Check for overflow before addition
            // require(result <= type(uint256).max - term, "Exp result overflow");
            result += term;
            
            // Break if term becomes too small
            if (term < PRECISION / 1e6) {
                break;
            }
        }
        
        return result;
    }

    function calculateK(uint32 totalTickets) public pure returns (uint256) {
        // Convert inputs to int256 safely
        // int256 totalTicketsInt = int256(uint256(totalTickets));
        // int256 minLowerPercent = int256(uint256(MIN_LOWER_SUPPLY_PERCENT));
        
        // Calculate denominator: (100 - 2 * MIN_LOWER_SUPPLY_PERCENT) * totalTickets
        uint256 multiplier = 100 - 2 * MIN_LOWER_SUPPLY_PERCENT;
        require(multiplier > 0, "Invalid MIN_LOWER_SUPPLY_PERCENT");
        
        // Prevent overflow in multiplication
        require(
            totalTickets <= type(uint256).max / multiplier,
            "Total tickets too large"
        );
        uint256 denominator = multiplier * totalTickets;
        
        // Prevent division by zero
        require(denominator > 0, "Invalid denominator");
        
        // Calculate k = (1000 * PRECISION) / denominator
        uint256 numerator = 1000 * PRECISION;
        require(
            numerator <= type(uint256).max / uint256(PRECISION),
            "Precision too large"
        );
        
        return numerator / denominator;
    }

    function abs(int256 x) internal pure returns (uint256) {
        return x < 0 ? uint256(-x) : uint256(x);
    }

    // function calculatePrice(
    //     uint256 basePrice,
    //     uint32 totalTickets,
    //     uint32 ticketsSold
    // ) public pure override returns (uint256) {
    //     if (ticketsSold >= totalTickets) return basePrice * 2;
    //     if (ticketsSold == 0) return basePrice;
        
    //     // Convert to uint256 first
    //     uint256 ticketsSoldU256 = uint256(ticketsSold);
    //     uint256 totalTicketsU256 = uint256(totalTickets);
        
    //     // Calculate normalized position (0 to 1)
    //     uint256 normalizedPosition = (ticketsSoldU256 * PRECISION) / totalTicketsU256;
        
    //     // Scale to [-4, 4] for smoother sigmoid shape
    //     int256 scaled = (int256(normalizedPosition) * 8 * int256(PRECISION)) / int256(PRECISION) - 4 * int256(PRECISION);
        
    //     // Get logistic value
    //     uint256 logisticValue = _logisticFunction(scaled);
        
    //     // Ensure smooth progression
    //     uint256 minValue = PRECISION / 20;    // 5% minimum
    //     uint256 maxValue = PRECISION;         // 100% maximum
        
    //     if (logisticValue < minValue) {
    //         logisticValue = minValue;
    //     } else if (logisticValue > maxValue) {
    //         logisticValue = maxValue;
    //     }
        
    //     // Calculate premium with bounds
    //     uint256 maxPremium = basePrice;  // Maximum premium is basePrice (to reach 2x)
    //     uint256 premium = (maxPremium * logisticValue) / PRECISION;
        
    //     return basePrice + premium;
    // }

    // function calculateBatchPrice(
    //     uint256 basePrice,
    //     uint32 totalTickets,
    //     uint32 ticketsSold,
    //     uint32 quantity
    // ) public pure override returns (uint256) {
    //     if (quantity == 0) return 0;
    //     if (ticketsSold >= totalTickets) return basePrice * 2 * quantity;

    //     uint256 totalCost = 0;
        
    //     // Calculate average price using 4 sample points
    //     uint256 sampleSize = quantity / 4;
    //     if (sampleSize == 0) sampleSize = 1;
        
    //     for (uint32 i = 0; i < quantity; i += uint32(sampleSize)) {
    //         uint32 currentTickets = ticketsSold + i;
    //         uint256 sampleQuantity = quantity - i < uint32(sampleSize) ? quantity - i : uint32(sampleSize);
            
    //         uint256 price = calculatePrice(basePrice, totalTickets, currentTickets);
    //         totalCost += price * sampleQuantity;
    //     }
        
    //     return totalCost;
    // }

    // function getBatchPriceComponents(
    //     uint256 basePrice,
    //     uint32 totalTickets,
    //     uint32 ticketsSold,
    //     uint32 quantity
    // ) external pure returns (uint256 baseCost, uint256 additionalCost) {
    //     if (quantity == 0) return (0, 0);
    //     if (ticketsSold >= totalTickets) return (basePrice * quantity, basePrice * quantity);

    //     // Calculate base cost
    //     baseCost = basePrice * quantity;
        
    //     // Calculate average premium
    //     uint256 totalPremium = 0;
    //     uint256 sampleSize = quantity / 4;
    //     if (sampleSize == 0) sampleSize = 1;
        
    //     for (uint32 i = 0; i < quantity; i += uint32(sampleSize)) {
    //         uint32 currentTickets = ticketsSold + i;
    //         uint256 sampleQuantity = quantity - i < uint32(sampleSize) ? quantity - i : uint32(sampleSize);
            
    //         // Get normalized position
    //         uint256 normalizedPosition = (currentTickets * PRECISION) / totalTickets;
    //         uint256 k = calculateK(totalTickets);
    //         int256 centered = int256(normalizedPosition) - int256(PRECISION / 2);
    //         int256 exponent = (int256(k) * centered) / int256(PRECISION);
            
    //         // Calculate premium for this sample
    //         uint256 logisticValue = _logisticFunction(exponent);
    //         uint256 premium = (basePrice * logisticValue) / PRECISION;
    //         totalPremium += premium * sampleQuantity;
    //     }
        
    //     additionalCost = totalPremium;
    //     return (baseCost, additionalCost);
    // }

    // function _logisticFunction(int256 exponent) private pure returns (uint256) {
    //     // Bound the exponent to prevent overflow
    //     if (exponent >= 10 * int256(PRECISION)) return PRECISION;
    //     if (exponent <= -10 * int256(PRECISION)) return 0;
        
    //     // Calculate e^(-x) using Taylor series with more terms for accuracy
    //     int256 expValue = int256(PRECISION); // Start with 1
    //     int256 term = int256(PRECISION);
    //     int256 negExponent = -exponent;
        
    //     for (uint256 i = 1; i <= 5; i++) {
    //         term = (term * negExponent) / int256(i * PRECISION);
    //         expValue += term;
    //     }
        
    //     if (expValue <= 0) return PRECISION;
        
    //     // Calculate 1 / (1 + e^(-x))
    //     uint256 denominator = uint256(int256(PRECISION) + expValue);
    //     return (PRECISION * PRECISION) / denominator;
    // }

    // // Helper functions for testing
    // function getLogisticValue(
    //     uint32 totalTickets,
    //     uint32 ticketsSold
    // ) external pure returns (uint256) {
    //     uint256 normalizedPosition = (ticketsSold * PRECISION) / totalTickets;
    //     uint256 k = calculateK(totalTickets);
    //     int256 centered = int256(normalizedPosition) - int256(PRECISION / 2);
    //     int256 exponent = (int256(k) * centered) / int256(PRECISION);
    //     return _logisticFunction(exponent);
    // }

    // function getK(uint32 totalTickets) external pure returns (uint256) {
    //     return calculateK(totalTickets);
    // }
}