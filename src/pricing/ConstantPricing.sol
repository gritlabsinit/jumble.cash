// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITicketPricing.sol";

contract ConstantPricing is ITicketPricing {
    function calculatePrice(
        uint256 basePrice,
        uint32 ,
        uint32 
    ) external pure returns (uint256) {
        return basePrice;
    }

    function calculateBatchPrice(
        uint256 basePrice,
        uint32 ,
        uint32 ,
        uint32 quantity
    ) external pure returns (uint256) {
        return basePrice * quantity;
    }
}
