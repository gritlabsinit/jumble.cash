// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./implementations/BatchRaffle.sol";
import "./pricing/ConstantPricing.sol";
import "./pricing/LogisticPricing.sol";

contract RaffleFactory is Ownable {
    enum PricingStrategy { CONSTANT, LOGISTIC }

    event RaffleDeployed(address indexed raffleAddress, PricingStrategy pricingStrategy);
    event PricingContractDeployed(address indexed pricingAddress, PricingStrategy strategy);

    // Mapping to store deployed raffle contracts
    mapping(address => bool) public isRaffleContract;
    
    // Mapping to store pricing strategy contracts
    mapping(PricingStrategy => address) public pricingContracts;
    
    // Entropy contract address
    address public immutable entropyAddress;
    
    constructor(address _entropyAddress) Ownable(msg.sender) {
        entropyAddress = _entropyAddress;
        
        // Deploy pricing strategy contracts
        ConstantPricing constantPricing = new ConstantPricing();
        LogisticPricing logisticPricing = new LogisticPricing();
        
        pricingContracts[PricingStrategy.CONSTANT] = address(constantPricing);
        pricingContracts[PricingStrategy.LOGISTIC] = address(logisticPricing);
        
        emit PricingContractDeployed(address(constantPricing), PricingStrategy.CONSTANT);
        emit PricingContractDeployed(address(logisticPricing), PricingStrategy.LOGISTIC);
    }

    function deployRaffle(
        PricingStrategy pricingStrategy,
        address feeCollector,
        uint256 feePercentage
    ) external onlyOwner returns (address) {
        address pricingContract = pricingContracts[pricingStrategy];
        require(pricingContract != address(0), "Invalid pricing strategy");

        BatchRaffle raffle = new BatchRaffle(
            entropyAddress,
            pricingContract,
            feeCollector,
            feePercentage
        );
        
        isRaffleContract[address(raffle)] = true;
        emit RaffleDeployed(address(raffle), pricingStrategy);
        
        return address(raffle);
    }

    function updatePricingContract(
        PricingStrategy strategy,
        address newContract
    ) external onlyOwner {
        require(newContract != address(0), "Invalid address");
        pricingContracts[strategy] = newContract;
        emit PricingContractDeployed(newContract, strategy);
    }
} 