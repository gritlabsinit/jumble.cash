// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/pricing/LogisticPricing.sol";

contract LogisticPricingTest is Test {
    LogisticPricing public pricing;
    
    // Test constants
    uint256 constant BASE_PRICE = 100e6;    // 100 USDC
    uint32 constant TOTAL_TICKETS = 100;     // 100 tickets total
    uint256 constant PRECISION = 1e6;
    uint256 constant MAX_UINT32 = type(uint32).max;

    function setUp() public {
        pricing = new LogisticPricing();
    }

    // Test 1: Basic Price Curve Shape
    function testPriceCurveShape() public {
        emit log_string("=== Price Curve Shape Test ===");
        
        uint256[] memory prices = new uint256[](11);
        for (uint32 i = 0; i <= 10; i++) {
            uint32 ticketsSold = i * 10; // 0, 10, 20, ..., 100
            prices[i] = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, ticketsSold);
            
            emit log_named_uint("Tickets Sold", ticketsSold);
            emit log_named_uint("Price (USDC)", prices[i] / PRECISION);
            emit log_string("---");
        }

        // Verify curve properties
        assertTrue(prices[0] < prices[5], "Price should increase from start to middle");
        assertTrue(prices[5] < prices[10], "Price should increase from middle to end");
        assertApproxEqRel(prices[0], BASE_PRICE, 0.1e18, "Starting price should be close to base price");
        assertApproxEqRel(prices[10], BASE_PRICE * 2, 0.1e18, "Final price should be close to 2x base price");
    }

    // Test 2: Price Sensitivity Analysis
    function testPriceSensitivity() public {
        emit log_string("=== Price Sensitivity Analysis ===");
        
        uint32[] memory supplyLevels = new uint32[](5);
        supplyLevels[0] = 0;
        supplyLevels[1] = 25;
        supplyLevels[2] = 50;
        supplyLevels[3] = 75;
        supplyLevels[4] = 95;

        for (uint256 i = 0; i < supplyLevels.length; i++) {
            uint32 currentSupply = supplyLevels[i];
            uint256 price1 = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, currentSupply);
            uint256 price2 = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, currentSupply + 1);
            
            emit log_named_uint("Supply Level", currentSupply);
            emit log_named_uint("Current Price (USDC)", price1 / PRECISION);
            emit log_named_uint("Next Price (USDC)", price2 / PRECISION);
            emit log_named_uint("Price Delta (USDC)", (price2 - price1) / PRECISION);
            emit log_string("---");

            assertTrue(price2 >= price1, "Price should never decrease");
            assertTrue(
                (price2 - price1) <= BASE_PRICE / 10,
                "Price increase per ticket should be reasonable"
            );
        }
    }

    // Test 3: Edge Cases
    function testEdgeCases() public {
        emit log_string("=== Edge Case Testing ===");

        // Test zero quantity
        uint256 zeroPrice = pricing.calculateBatchPrice(BASE_PRICE, TOTAL_TICKETS, 0, 0);
        assertEq(zeroPrice, 0, "Zero quantity should cost zero");

        // Test full supply
        uint256 fullPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, TOTAL_TICKETS);
        assertEq(fullPrice, BASE_PRICE * 2, "Full supply should cost 2x base price");

        // Test over supply - should revert
        vm.expectRevert("Supply exceeds total");
        pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, TOTAL_TICKETS + 1);

        // Test single ticket at different supply levels
        uint32[] memory supplyLevels = new uint32[](4);
        supplyLevels[0] = 0;
        supplyLevels[1] = TOTAL_TICKETS / 4;
        supplyLevels[2] = TOTAL_TICKETS / 2;
        supplyLevels[3] = (TOTAL_TICKETS * 3) / 4;

        for (uint256 i = 0; i < supplyLevels.length; i++) {
            uint256 price = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, supplyLevels[i]);
            assertTrue(price >= BASE_PRICE, "Price should never be below base price");
            assertTrue(price <= BASE_PRICE * 2, "Price should never exceed 2x base price");
        }
    }

    // Test 4: Overflow Protection
    function testOverflowProtection() public {
        emit log_string("=== Overflow Protection Test ===");

        // Test max uint32 values
        uint32 maxUint32 = type(uint32).max;
        uint256 maxPrice = pricing.calculatePrice(
            BASE_PRICE,
            maxUint32,
            maxUint32
        );
        assertEq(maxPrice, BASE_PRICE * 2, "Max supply should cost 2x base price");

        // Test large batch with max values
        uint32 nearMaxUint32 = maxUint32 - 1000;
        uint256 largeBatchPrice = pricing.calculateBatchPrice(
            BASE_PRICE,
            maxUint32,
            nearMaxUint32,
            1000
        );
        assertTrue(largeBatchPrice > 0, "Large batch should have positive price");
        assertTrue(
            largeBatchPrice <= BASE_PRICE * 2 * 1000,
            "Large batch should not exceed max possible price"
        );

        // Test extreme price values
        uint256 extremeBasePrice = type(uint256).max / (4 * PRECISION);
        uint256 extremePrice = pricing.calculatePrice(
            extremeBasePrice,
            TOTAL_TICKETS,
            TOTAL_TICKETS / 2
        );
        assertTrue(extremePrice >= extremeBasePrice, "Extreme price should be handled safely");

        // Test near max values
        uint32 largeSupply = maxUint32 / 2;
        uint256 largeSupplyPrice = pricing.calculatePrice(
            BASE_PRICE,
            largeSupply,
            largeSupply / 2
        );
        assertTrue(
            largeSupplyPrice >= BASE_PRICE && largeSupplyPrice <= BASE_PRICE * 2,
            "Large supply should have reasonable price"
        );
    }

    // Test 5: Batch Pricing Accuracy
    function testBatchPricingAccuracy() public {
        emit log_string("=== Batch Pricing Accuracy Test ===");

        uint32[] memory batchSizes = new uint32[](3);
        batchSizes[0] = 5;
        batchSizes[1] = 10;
        batchSizes[2] = 20;

        for (uint256 i = 0; i < batchSizes.length; i++) {
            uint32 batchSize = batchSizes[i];
            
            // Compare batch price with sum of individual prices
            uint256 batchPrice = pricing.calculateBatchPrice(
                BASE_PRICE,
                TOTAL_TICKETS,
                0,
                batchSize
            );

            uint256 sumIndividual = 0;
            for (uint32 j = 0; j < batchSize; j++) {
                sumIndividual += pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, j);
            }

            // Allow for small rounding differences
            assertApproxEqRel(
                batchPrice,
                sumIndividual,
                0.01e18,
                "Batch price should approximate sum of individual prices"
            );
        }
    }

    // Test 6: Price Curve Monotonicity
    function testPriceMonotonicity() public {
        emit log_string("=== Price Monotonicity Test ===");

        uint256 lastPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, 0);
        
        // Test price at every ticket level
        for (uint32 i = 1; i <= TOTAL_TICKETS; i++) {
            uint256 currentPrice = pricing.calculatePrice(BASE_PRICE, TOTAL_TICKETS, i);
            assertTrue(
                currentPrice >= lastPrice,
                "Price should never decrease"
            );
            lastPrice = currentPrice;
        }
    }

    // Test 7: K Value Analysis
    function testKValueBehavior() public {
        emit log_string("=== K Value Analysis ===");

        uint32[] memory supplies = new uint32[](4);
        supplies[0] = 100;
        supplies[1] = 1000;
        supplies[2] = 10000;
        supplies[3] = 100000;

        for (uint256 i = 0; i < supplies.length; i++) {
            uint256 k = pricing.calculateK(supplies[i]);
            emit log_named_uint("Total Supply", supplies[i]);
            emit log_named_uint("K Value", k / PRECISION);
            
            assertTrue(k > 0, "K value should be positive");
            assertTrue(
                k < 1000 * PRECISION,
                "K value should be reasonable"
            );
        }
    }
} 