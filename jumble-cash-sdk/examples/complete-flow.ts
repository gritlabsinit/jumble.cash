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
    TOKEN_ADDRESS,
} = process.env;

const BLOCK_TIME: number = parseInt(process.env.BLOCK_TIME || '3000', 10);

if (!RPC_URL || !PRIVATE_KEY || !RAFFLE_ADDRESS || !TOKEN_ADDRESS || !BLOCK_TIME) {
    throw new Error('Missing required environment variables. Please check your .env file');
}

async function createRaffle(raffleSdk: RaffleSdk, distribution: any, raffleId: number | null) {
    let raffleEvent;

    if (raffleId == null) {  
        raffleEvent = await raffleSdk.createRaffle(
            100, // totalTickets
            ethers.parseEther('1'), // 1 token per ticket
            distribution,
            100, // duration in blocks
            1 // minTicketsRequired
        );

        console.log('Created raffle:', {
            raffleId: raffleEvent?.raffleId.toString(),
            creator: raffleEvent?.creator,
            totalTickets: raffleEvent?.totalTickets.toString()
        });

        return raffleEvent?.raffleId;
    }
    
    return raffleId;
    // return await raffleSdk.getRaffleInfo(raffleId);    
}

async function buyTickets(raffleSdk: RaffleSdk, raffleId: number, ticketQuantity: number) {
    // Buy tickets
    const batchSize = 5;
    for (let i = 0; i < ticketQuantity; i+=batchSize) {
        try {       
            const purchaseEvent = await raffleSdk.buyTickets(Number(raffleId), batchSize);
            console.log('Bought tickets:', {
                raffleId: purchaseEvent?.raffleId.toString(),
                buyer: purchaseEvent?.buyer,
                quantity: purchaseEvent?.quantity.toString()
            });    
        } catch (error) {
            console.error('Error buying tickets:', error);
        }
    }
}

async function refundTickets(raffleSdk: RaffleSdk, raffleId: number, ticketQuantity: number) {
    // Refund tickets
    for (let i = 0; i < ticketQuantity; i++) {
        try {   
            const refundEvent = await raffleSdk.refundTicket(Number(raffleId), i);
            console.log('Refunded tickets:', {
                raffleId: refundEvent?.raffleId.toString(),
                user: refundEvent?.user,
                ticketId: refundEvent?.ticketId.toString()
            });
        } catch (error) {
            console.error('Error refunding ticket:', error);
        }

        // Wait for 1 second before refunding the next ticket
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
}

async function finalizeRaffle(raffleSdk: RaffleSdk, raffleId: number) {
    const finalizationEvent = await raffleSdk.finalizeRaffle(Number(raffleId));
    console.log('Finalized raffle:', {
        raffleId: finalizationEvent?.raffleId.toString(),
        randomSeed: finalizationEvent?.sequenceNumber.toString()
    });
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

    // let _raffleId = 4;
    let _raffleId = null;

    try {
        // Create a new raffle
        const distribution = [
            { fundPercentage: 70, ticketQuantity: 10 },
            { fundPercentage: 20, ticketQuantity: 50 },
            { fundPercentage: 10, ticketQuantity: 40 },
        ];

        // Number of tickets to buy
        const ticketToBuy = 30;

        // Number of tickets to refund
        const ticketToRefund = 10;

        let raffleId = await createRaffle(raffleSdk, distribution, _raffleId);

        await buyTickets(raffleSdk, Number(raffleId), ticketToBuy);

        await refundTickets(raffleSdk, Number(raffleId), ticketToRefund);

        await buyTickets(raffleSdk, Number(raffleId), 5);

        // Wait for raffle duration
        const raffleInfo = await raffleSdk.getRaffleInfo(Number(raffleId));
        const currentBlock = await provider.getBlockNumber();
        const blocksToWait = Number(raffleInfo.endBlock) - currentBlock;
        
        // Wait for raffle duration 
        console.log(`Waiting for ${blocksToWait} blocks...`);
        await new Promise(resolve => setTimeout(resolve, blocksToWait * BLOCK_TIME));

        // Finalize raffle
        await finalizeRaffle(raffleSdk, Number(raffleId));

        console.log(`Waiting for ${blocksToWait} blocks...`);
        await new Promise(resolve => setTimeout(resolve, blocksToWait * BLOCK_TIME));

        // Select winners
        const winnersEvent = await raffleSdk.selectWinners(Number(raffleId));
        console.log('Winners selected:', {
            raffleId: winnersEvent?.raffleId.toString(),
            validTickets: winnersEvent?.validTickets.toString()
        });

        // Claim prize
        const claimEvent = await raffleSdk.claimPrize(Number(raffleId));
        console.log('Claimed prize:', {
            raffleId: claimEvent?.raffleId.toString(),
            winner: claimEvent?.winner,
            amount: claimEvent?.amount.toString()
        });

        // Get final raffle state
        const finalRaffleInfo = await raffleSdk.getRaffleInfo(Number(raffleId));
        console.log('Final raffle state:', finalRaffleInfo);

    } catch (error) {
        console.error('Error in raffle flow:', error);
        throw error;
    }
}

main().catch(console.error); 