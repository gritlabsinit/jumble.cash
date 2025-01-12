// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";
import { EntropyStructs } from "@pythnetwork/entropy-sdk-solidity/EntropyStructs.sol";

contract MockEntropy is IEntropy {
    uint256 private mockRandomness = 123456789;
    uint128 private mockFee = 0.01 ether;
    mapping(uint64 => bytes32) public commitments;
    address public defaultProvider;
    
    constructor() {
        defaultProvider = address(1);
    }

    function setMockRandomness(uint256 _randomness) external {
        mockRandomness = _randomness;
    }

    function register(
        uint128,
        bytes32,
        bytes calldata,
        uint64,
        bytes calldata
    ) external pure {
        revert("Not implemented");
    }

    function withdraw(uint128) external pure {
        revert("Not implemented");
    }

    function withdrawAsFeeManager(address, uint128) external pure {
        revert("Not implemented");
    }

    function request(
        address,
        bytes32,
        bool
    ) external payable returns (uint64) {
        return 1;
    }

    function requestWithCallback(
        address,
        bytes32
    ) external payable returns (uint64) {
        return 1;
    }

    function reveal(
        address,
        uint64,
        bytes32,
        bytes32
    ) external pure returns (bytes32) {
        return bytes32(uint256(123456789));
    }

    function revealWithCallback(
        address,
        uint64,
        bytes32,
        bytes32
    ) external {
        // Mock implementation
    }

    function getProviderInfo(
        address
    ) external pure returns (EntropyStructs.ProviderInfo memory) {
        return EntropyStructs.ProviderInfo({
            feeInWei: 0.01 ether,
            accruedFeesInWei: 0,
            originalCommitment: bytes32(0),
            originalCommitmentSequenceNumber: 0,
            commitmentMetadata: new bytes(0),
            uri: new bytes(0),
            endSequenceNumber: 1,
            sequenceNumber: 0,
            currentCommitment: bytes32(0),
            currentCommitmentSequenceNumber: 0,
            feeManager: address(0)
        });
    }

    function getDefaultProvider() external view returns (address) {
        return defaultProvider;
    }

    function getRequest(
        address,
        uint64
    ) external pure returns (EntropyStructs.Request memory) {
        return EntropyStructs.Request({
            provider: address(0),
            sequenceNumber: 0,
            numHashes: 0,
            commitment: bytes32(0),
            blockNumber: 0,
            requester: address(0),
            useBlockhash: false,
            isRequestWithCallback: false
        });
    }

    function getFee(address) external view returns (uint128) {
        return mockFee;
    }

    function getAccruedPythFees() external pure returns (uint128) {
        return 0;
    }

    function setProviderFee(uint128) external pure {
        revert("Not implemented");
    }

    function setProviderFeeAsFeeManager(address, uint128) external pure {
        revert("Not implemented");
    }

    function setProviderUri(bytes calldata) external pure {
        revert("Not implemented");
    }

    function setFeeManager(address) external pure {
        revert("Not implemented");
    }

    function constructUserCommitment(bytes32 userRandomness) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(userRandomness));
    }

    function combineRandomValues(
        bytes32 userRandomness,
        bytes32 providerRandomness,
        bytes32 blockHash
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(userRandomness, providerRandomness, blockHash));
    }
}