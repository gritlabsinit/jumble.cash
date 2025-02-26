# Raffle Smart Contract System

A gas-optimized raffle system built on Ethereum, featuring a Solidity smart contract and TypeScript SDK for easy integration.

## Features

- Create raffles with customizable ticket distributions and prize pools
- Purchase tickets using ERC20 tokens
- Refund functionality for individual tickets
- Minimum ticket requirements for raffle completion
- Automated winner selection using block-based randomness
- Prize claiming system with multiple prize pools
- TypeScript SDK for easy contract interaction

## Project Structure

```
jumble_cash/
├── src/
│   ├── base/
│   │   ├── BaseRaffle.sol       # Base raffle implementation
│   │   └── RaffleStorage.sol    # Storage layout contract
│   ├── implementations/
│   │   ├── BatchRaffle.sol      # Batch ticket purchase implementation
│   │   └── IndividualRaffle.sol # Individual ticket purchase implementation
│   ├── interfaces/
│   │   ├── IRaffle.sol          # Main raffle interface
│   │   ├── IRaffleState.sol     # Raffle state interface
│   │   └── ITicketPricing.sol   # Ticket pricing interface
│   └── libraries/
│       └── RaffleLib.sol        # Shared raffle utilities
│
├── jumble-cash-sdk/
│   ├── src/
│   │   ├── abis/               # Generated contract ABIs
│   │   │   ├── BatchRaffle.ts
│   │   │   └── MockERC20.ts
│   │   └── raffle-sdk.ts       # TypeScript SDK implementation
│   └── examples/
│       └── complete-flow.ts    # SDK usage examples
│
├── scripts/
│   ├── deploy_contracts.sh     # Deployment script
│   ├── gen_abi.py             # ABI generation script
│   └── generate-abi-types.ts   # TypeScript ABI type generator
│
├── test/
│   └── Raffle.t.sol           # Contract test suite
│
└── README.md
```

### Key Components

- **Base Contracts**: Core raffle functionality and storage layout
- **Implementations**: Specific raffle variants (Batch and Individual)
- **Interfaces**: Contract interfaces and type definitions
- **Libraries**: Shared utilities and helper functions
- **SDK**: TypeScript library for contract interaction
- **Scripts**: Deployment and development utilities
- **Tests**: Comprehensive test suite

## Deployed Contracts

### Base Sepolia
- **Raffle Contract with Constant Pricing**: [`0xc63300cF3bAD557CeBdf945DcB9B8888b0e46d65`](https://sepolia.basescan.org/address/0xc63300cF3bAD557CeBdf945DcB9B8888b0e46d65)
- **Raffle Contract with Logistic Pricing**: [`0xC011843bE30902f054EAf6c75ad06E143dd37BE3`](https://sepolia.basescan.org/address/0xC011843bE30902f054EAf6c75ad06E143dd37BE3)
- **Token Contract**: [`0xBF54df82439ed2b723de0721e5e9A40034155Fb1`](https://sepolia.basescan.org/address/0xBF54df82439ed2b723de0721e5e9A40034155Fb1)
- **Factory Contract**: [`0xb43602Bdc9550Cb7D730E6c98345C26E04F86bc1`](https://sepolia.basescan.org/address/0xb43602Bdc9550Cb7D730E6c98345C26E04F86bc1)

## Getting Started

1. Clone the repository
2. Install dependencies
3. Run the tests
4. Use the SDK to interact with the Raffle contract 


# Install Solidity dependencies
```
forge install
```

### Scripts

#### Deploy Contracts
The `deploy_contracts.py` script helps deploy and verify contracts on different networks:

```
source .env && ./deploy_contracts.sh
```

#### Generate ABIs
The `gen_abi.py` script extracts and formats contract ABIs:

bash
Generate ABIs for all contracts
python3 scripts/gen_abi.py
The script will:
1. Read contract artifacts from the out/ directory
2. Extract ABIs
3. Save them to src/abi/ directory

# Run tests
```
forge test
``` 

# Run tests with coverage
```
forge coverage
```     


## Deployment

1. Deploy the contracts:
```
forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --private-key <your_private_key>
```

2. Interact with the contracts using the SDK:
```
npm run jump-cash-sdk/examples
```


See `ts/examples/complete-flow.ts` for a complete usage example.

## Contract Features

### Raffle Creation
- Set total number of tickets
- Define ticket price in ERC20 tokens
- Configure prize distribution across multiple pools
- Set minimum ticket requirements
- Set raffle duration in blocks

### Ticket Management
- Purchase multiple tickets
- Refund individual tickets
- Track ticket ownership
- View user tickets

### Raffle Finalization
- Automatic winner selection
- Multiple prize pools
- Null raffle handling
- Prize claiming system

## Security Features

- Reentrancy protection
- Safe math operations
- Owner controls
- Gas optimization
- Proper event emission


## Changelog

- 0.0.1: Initial release   
- 0.0.2: Added raffle state management and winner selection
- 0.0.3: Added ticket refund map and ticket owner and prize mapping

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.