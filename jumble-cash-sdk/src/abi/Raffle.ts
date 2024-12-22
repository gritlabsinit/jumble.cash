export const RaffleABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "entropyAddress",
        "type": "address",
        "internalType": "address"
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
        "internalType": "struct Raffle.TicketDistribution[]",
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
        "name": "totalSold",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "availableTickets",
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
        "name": "totalSold",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "availableTickets",
        "type": "uint32",
        "internalType": "uint32"
      },
      {
        "name": "sequenceNumber",
        "type": "uint64",
        "internalType": "uint64"
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
        "type": "uint256",
        "internalType": "uint256"
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
