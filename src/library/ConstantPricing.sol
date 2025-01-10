// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITicketPricing.sol";

contract ConstantPricing is ITicketPricing {
    function calculatePrice(
        uint256 _basePrice,
        uint32 _totalTickets,
        uint32 _ticketsSold
    ) external pure returns (uint256) {
        return _basePrice;
    }

    function calculateBatchPrice(
        uint256 _basePrice,
        uint32 _totalTickets,
        uint32 _ticketsSold,
        uint32 _quantity
    ) external pure returns (uint256) {
        return _basePrice * _quantity;
    }
}
