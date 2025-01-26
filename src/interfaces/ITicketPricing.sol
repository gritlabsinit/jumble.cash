// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITicketPricing {
    // Single ticket price calculation
    function calculatePrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold
    ) external pure returns (uint256);

    // Batch ticket price calculation
    function calculateBatchPrice(
        uint256 basePrice,
        uint32 totalTickets,
        uint32 ticketsSold,
        uint32 quantity
    ) external pure returns (uint256);
}