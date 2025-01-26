// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { UD60x18, ud , convert} from "@prb-math/UD60x18.sol";
import "../interfaces/ITicketPricing.sol";

contract LogisticPricing is ITicketPricing{
    uint256 private constant MIN_LOWER_SUPPLY_PERCENT = 30;

    function calculatePrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold
    ) public pure returns (uint256 price) {
        require(ticketsSold <= totalTickets, "Supply exceeds total");
        require(basePrice <= type(uint256).max / 3, "Base price too large");

        // Early return for edge case
        if (ticketsSold == totalTickets) return basePrice * 2;

        // Convert to UD60x18 - Safe as totalTickets is uint32
        UD60x18 k = calculateK(totalTickets);
        
        // Safe conversions as ticketsSold and totalTickets are uint32
        UD60x18 position = convert(uint256(ticketsSold));
        UD60x18 midPoint = convert(uint256(totalTickets)).div(ud(2e18));

        UD60x18 logisticValue;
        UD60x18 exponent;
        UD60x18 sMid;
        if (position < midPoint) {
            sMid = midPoint - position;
            
            // Check for k*sMid overflow
            require(k.unwrap() <= type(uint256).max / sMid.unwrap(), "k*sMid overflow");
            exponent = (k * sMid);
            
            // Calculate logistic value: 1 / (1 + e^(-k(S - Smax/2)))
            UD60x18 expValue = exponent.exp();
            logisticValue = ud(1e18) / (ud(1e18) + expValue);
        } else {
            sMid = position - midPoint;
            
            // Check for k*sMid overflow
            // require(k.unwrap() <= type(uint256).max / sMid.unwrap(), "k*sMid overflow");
            exponent = (k * sMid);

            // Calculate logistic value: 1 / (1 + e^(-k(Smax/2 - S)))
            UD60x18 expValue = exponent.exp();
            logisticValue = expValue / (ud(1e18) + expValue);
        }

        // Check for basePrice conversion overflow
        require(basePrice <= type(uint256).max / 1e18, "Base price too large for conversion");
        UD60x18 baseUD = convert(basePrice);
        
        // Check for premium calculation overflow
        // require(logisticValue.unwrap() <= type(uint256).max / baseUD.unwrap(), "Premium calc overflow");
        UD60x18 premium = baseUD * logisticValue;
        
        // Check final addition
        require(premium.unwrap() <= type(uint256).max - baseUD.unwrap(), "Final price overflow");
        UD60x18 finalPrice = baseUD + premium;

        return convert(finalPrice);
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


    function calculateK(uint32 totalTickets) public pure returns (UD60x18) {
        uint256 multiplier = 100 - 2 * MIN_LOWER_SUPPLY_PERCENT;
        require(multiplier > 0, "Invalid MIN_LOWER_SUPPLY_PERCENT");
        
        require(
            totalTickets <= type(uint256).max / multiplier,
            "Total tickets too large"
        );
        
        uint256 denominator = multiplier * totalTickets;
        require(denominator > 0, "Invalid denominator");
        
        return convert(1000e18) / convert(denominator*1e18);
    }
}