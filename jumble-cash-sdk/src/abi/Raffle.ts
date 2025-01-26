export const RaffleABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "entropyAddress",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_ticketPricing",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_feeCollector",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_feePercentage",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "_entropyCallback",
    "inputs": [
      {
        "name": "sequence",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "provider",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "randomNumber",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "buyTickets",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "quantity",
        "type": "uint32",
        "internalType": "uint32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "claimPrize",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "claimPrizeByTicketIds",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketIds",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "claimRefund",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "claimRefundByTicketIds",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketIds",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "createRaffle",
    "inputs": [
      {
        "name": "totalTickets",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketToken",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "ticketTokenQuantity",
        "type": "uint96",
        "internalType": "uint96"
      },
      {
        "name": "distribution",
        "type": "tuple[]",
        "internalType": "struct IRaffle.TicketDistribution[]",
        "components": [
          {
            "name": "fundPercentage",
            "type": "uint96",
            "internalType": "uint96"
          },
          {
            "name": "ticketQuantity",
            "type": "uint96",
            "internalType": "uint96"
          }
        ]
      },
      {
        "name": "duration",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "minTicketsRequired",
        "type": "uint32",
        "internalType": "uint32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "entropy",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IEntropy"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "feeCollector",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "feePercentage",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "finalizeRaffle",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getFeeCollector",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getFeePercentage",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRaffleInfo",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "ticketToken",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "ticketTokenQuantity",
        "type": "uint96",
        "internalType": "uint96"
      },
      {
        "name": "endBlock",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "minTicketsRequired",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsRefunded",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsMinted",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsAvailable",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "isActive",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "isFinalized",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "isNull",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getSequenceFees",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getTicketInfo",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "prizeShare",
        "type": "uint96",
        "internalType": "uint96"
      },
      {
        "name": "purchasePrice",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getUserTickets",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "user",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getWinningTicketsForPool",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "poolIndex",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "raffleCounter",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "raffles",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketToken",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "ticketTokenQuantity",
        "type": "uint96",
        "internalType": "uint96"
      },
      {
        "name": "totalTickets",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsMinted",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsRefunded",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "ticketsAvailable",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "sequenceNumber",
        "type": "uint64",
        "internalType": "uint64"
      },
      {
        "name": "randomSeed",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "feeCollected",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "totalPoolTokenQuantity",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "minTicketsRequired",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "endBlock",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "isActive",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "isFinalized",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "isNull",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "refundTicket",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketId",
        "type": "uint32",
        "internalType": "uint32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "refundTicketsByTicketIds",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "ticketIds",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "selectWinners",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "sequenceNumberToRaffleId",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setFeeCollector",
    "inputs": [
      {
        "name": "_feeCollector",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setFeePercentage",
    "inputs": [
      {
        "name": "_feePercentage",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setTicketPricing",
    "inputs": [
      {
        "name": "_ticketPricing",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "ticketPricing",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract ITicketPricing"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "FeeCollected",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PoolPrizeCreated",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "poolIndex",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "poolPrize",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "prizePerWinner",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PrizeClaimed",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "winner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "PrizeClaimedForTicketIds",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "winner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "ticketIds",
        "type": "uint256[]",
        "indexed": false,
        "internalType": "uint256[]"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RaffleCreated",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "creator",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "totalTickets",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RaffleDeclaredNull",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RaffleFinalized",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "randomSeed",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RaffleStateUpdated",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "isActive",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RefundClaimedForTicketIds",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "user",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "ticketIds",
        "type": "uint256[]",
        "indexed": false,
        "internalType": "uint256[]"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "SequenceNumberRequested",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "sequenceNumber",
        "type": "uint64",
        "indexed": false,
        "internalType": "uint64"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TicketRefunded",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "user",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "ticketId",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TicketsPurchased",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "buyer",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "quantity",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "WinnersSelected",
    "inputs": [
      {
        "name": "raffleId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "validTickets",
        "type": "uint32",
        "indexed": false,
        "internalType": "uint32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "AlreadyClaimed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InsufficientTickets",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidDistribution",
    "inputs": []
  },
  {
    "type": "error",
    "name": "InvalidTicketId",
    "inputs": []
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "RaffleAlreadyFinalized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RaffleExpired",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RaffleIsNull",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RaffleNotActive",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RaffleNotEnded",
    "inputs": []
  },
  {
    "type": "error",
    "name": "RaffleNotFinalized",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  },
  {
    "type": "error",
    "name": "TicketAlreadyRefunded",
    "inputs": []
  },
  {
    "type": "error",
    "name": "TicketNotOwned",
    "inputs": []
  },
  {
    "type": "error",
    "name": "ZeroAddress",
    "inputs": []
  }
]
