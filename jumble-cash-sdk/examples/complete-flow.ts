import { ethers } from 'ethers';
import { RaffleSdk } from '../src/raffle-sdk';
import { config } from 'dotenv';

// Load environment variables
config();

// Validate environment variables
const {
    RPC_URL,
    PRIVATE_KEY,
    RAFFLE_ADDRESS,
    TOKEN_ADDRESS
} = process.env;

if (!RPC_URL || !PRIVATE_KEY || !RAFFLE_ADDRESS || !TOKEN_ADDRESS) {
    throw new Error('Missing required environment variables. Please check your .env file');
}

async function main() {
    // Setup provider and signer
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const signer = new ethers.Wallet(PRIVATE_KEY as string, provider);

    // Initialize SDK
    const raffleSdk = new RaffleSdk(
        provider,
        signer,
        RAFFLE_ADDRESS as string,
        TOKEN_ADDRESS as string
    );

    try {
        // Create a new raffle
        const distribution = [
            { fundPercentage: 70, ticketQuantity: 2 },
            { fundPercentage: 20, ticketQuantity: 5 },
            { fundPercentage: 10, ticketQuantity: 3 }
        ];

        const raffleEvent = await raffleSdk.createRaffle(
            10, // totalTickets
            ethers.parseEther('1'), // 1 token per ticket
            distribution,
            10, // duration in blocks
            2 // minTicketsRequired
        );

        console.log('Created raffle:', {
            raffleId: raffleEvent?.raffleId.toString(),
            creator: raffleEvent?.creator,
            totalTickets: raffleEvent?.totalTickets.toString()
        });

        // Buy tickets
        const purchaseEvent = await raffleSdk.buyTickets(Number(raffleEvent?.raffleId), 4);
        console.log('Bought tickets:', {
            raffleId: purchaseEvent?.raffleId.toString(),
            buyer: purchaseEvent?.buyer,
            quantity: purchaseEvent?.quantity.toString()
        });
        
        // Wait for raffle duration
        const raffleInfo = await raffleSdk.getRaffleInfo(Number(raffleEvent?.raffleId));
        const currentBlock = await provider.getBlockNumber();
        const blocksToWait = Number(raffleInfo.endBlock) - currentBlock;
        
        console.log(`Waiting for ${blocksToWait} blocks...`);
        // In real application, you would wait for the actual blocks
        // This is just for demonstration
        await new Promise(resolve => setTimeout(resolve, blocksToWait * 12000));

        // Finalize raffle
        const finalizationEvent = await raffleSdk.finalizeRaffle(Number(raffleEvent?.raffleId));
        console.log('Finalized raffle:', {
            raffleId: finalizationEvent?.raffleId.toString(),
            randomSeed: finalizationEvent?.sequenceNumber.toString()
        });

        console.log(`Waiting for ${blocksToWait} blocks...`);
        // In real application, you would wait for the actual blocks
        // This is just for demonstration
        await new Promise(resolve => setTimeout(resolve, blocksToWait * 12000));

        // Claim prize
        const claimEvent = await raffleSdk.claimPrize(Number(raffleEvent?.raffleId));
        console.log('Claimed prize:', {
            raffleId: claimEvent?.raffleId.toString(),
            winner: claimEvent?.winner,
            amount: claimEvent?.amount.toString()
        });

        // Get final raffle state
        const finalRaffleInfo = await raffleSdk.getRaffleInfo(Number(raffleEvent?.raffleId));
        console.log('Final raffle state:', finalRaffleInfo);

    } catch (error) {
        console.error('Error in raffle flow:', error);
        throw error;
    }
}

main().catch(console.error); 