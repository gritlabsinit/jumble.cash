import { ethers } from 'ethers';
import { RaffleABI } from './abi/Raffle';
import { ERC20ABI } from './abi/ERC20';
import { ErrorDecoder } from 'ethers-decode-error'
import type { DecodedError } from 'ethers-decode-error'

interface RaffleEvent {
    raffleId: bigint;
    creator: string;
    totalTickets: bigint;
}

interface TicketsPurchasedEvent {
    raffleId: bigint;
    buyer: string;
    quantity: bigint;
}

interface RaffleFinalizationEvent {
    raffleId: bigint;
    randomSeed: bigint;
}

interface PrizeClaimedEvent {
    raffleId: bigint;
    winner: string;
    amount: bigint;
}

interface SequenceNumberRequestedEvent {
    raffleId: bigint;
    sequenceNumber: bigint;
}

interface WinnersSelectedEvent {
    raffleId: bigint;
    validTickets: number;
}

interface TicketRefundedEvent {
    raffleId: bigint;
    user: string;
    ticketId: bigint;
}

export class RaffleSdk {
    private provider: ethers.Provider;
    private signer: ethers.Signer;
    private raffleContract: ethers.Contract;
    private tokenContract: ethers.Contract;
    private raffleContractAddress: string;
    private errorDecoder: ErrorDecoder;

    constructor(
        provider: ethers.Provider,
        signer: ethers.Signer,
        raffleAddress: string,
        tokenAddress: string
    ) {
        this.provider = provider;
        this.signer = signer;
        this.raffleContract = new ethers.Contract(raffleAddress, RaffleABI, signer);
        this.tokenContract = new ethers.Contract(tokenAddress, ERC20ABI, signer);
        this.raffleContractAddress = raffleAddress;
        this.errorDecoder = ErrorDecoder.create([RaffleABI, ERC20ABI]);
    }

    async createRaffle(
        totalTickets: number,
        ticketTokenQuantity: bigint,
        distribution: Array<{ fundPercentage: number; ticketQuantity: number }>,
        duration: number,
        minTicketsRequired: number
    ): Promise<RaffleEvent | null> {
        try {
            const tx = await this.raffleContract.createRaffle(
                totalTickets,
                await this.tokenContract.getAddress(),
                ticketTokenQuantity,
                distribution,
                duration,
                minTicketsRequired
            );
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'RaffleCreated');
            
            if (!event) {
                console.warn('RaffleCreated event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                creator: event.args[1],
                totalTickets: event.args[2]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error creating raffle:', decodedError);
            throw decodedError;
        }
    }

    async buyTickets(raffleId: number, quantity: number): Promise<TicketsPurchasedEvent | null> {
        try {
            const raffleInfo = await this.raffleContract.getRaffleInfo(raffleId);
            // provide 2x the ticket token quantity for the total cost
            const totalCost = BigInt(2) *raffleInfo.ticketTokenQuantity * BigInt(quantity);

            // Approve tokens first
            const approveTx = await this.tokenContract.approve(
                await this.raffleContract.getAddress(),
                totalCost
            );
            await approveTx.wait();

            // Buy tickets with uint32 quantity
            const tx = await this.raffleContract.buyTickets(raffleId, quantity);
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'TicketsPurchased');
            
            if (!event) {
                console.warn('TicketsPurchased event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                buyer: event.args[1],
                quantity: event.args[2]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error buying tickets:', decodedError);
            throw decodedError;
        }
    }

    async finalizeRaffle(raffleId: number): Promise<SequenceNumberRequestedEvent | null> {
        try {
            const sequenceFees = await this.getSequenceFees();
            const tx = await this.raffleContract.finalizeRaffle(raffleId, {
                value: ethers.parseEther(ethers.formatEther(sequenceFees))
            });
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'SequenceNumberRequested');
            
            if (!event) {
                console.warn('SequenceNumberRequested event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                sequenceNumber: event.args[1]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error finalizing raffle:', decodedError);
            throw decodedError;
        }
    }

    async selectWinners(raffleId: number): Promise<WinnersSelectedEvent | null> {
        try {
            const tx = await this.raffleContract.selectWinners(raffleId);
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'WinnersSelected');
            
            if (!event) {
                console.warn('WinnersSelected event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                validTickets: event.args[1]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error selecting winners:', decodedError);
            throw decodedError;
        }
    }

    async claimPrize(raffleId: number): Promise<PrizeClaimedEvent | null> {
        try {
            const tx = await this.raffleContract.claimPrize(raffleId);
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'PrizeClaimed');
            
            if (!event) {
                console.warn('PrizeClaimed event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                winner: event.args[1],
                amount: event.args[2]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error claiming prize:', decodedError);
            throw decodedError;
        }
    }

    async refundTicket(raffleId: number, ticketId: number): Promise<TicketRefundedEvent | null> {
        try {
            const tx = await this.raffleContract.refundTicket(raffleId, ticketId);
            const receipt = await tx.wait();
            const event = this.parseEvent(receipt, 'TicketRefunded');
            
            if (!event) {
                console.warn('TicketRefunded event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                user: event.args[1],
                ticketId: event.args[2]
            };
        } catch (error) {
            const decodedError: DecodedError = await this.errorDecoder.decode(error)          
            console.error('Error refunding ticket:', decodedError);
            throw decodedError;
        }
    }

    // View functions
    async getRaffleInfo(raffleId: number) {
        try {
            const info = await this.raffleContract.getRaffleInfo(raffleId);
            return {
                ticketToken: info.ticketToken,
                ticketTokenQuantity: info.ticketTokenQuantity,
                endBlock: info.endBlock,
                ticketDistribution: info.ticketDistribution,
                totalTickets: info.totalTickets,
                minTicketsRequired: info.minTicketsRequired,
                ticketsRefunded: info.ticketsRefunded,
                ticketsMinted: info.ticketsMinted,
                ticketsAvailable: info.ticketsAvailable,
                isActive: info.isActive,
                isFinalized: info.isFinalized,
                isNull: info.isNull
            };
        } catch (error) {
            console.error('Error getting raffle info:', error);
            throw error;
        }
    }

    async getUserTickets(raffleId: number, userAddress: string) {
        try {
            return await this.raffleContract.getUserTickets(raffleId, userAddress);
        } catch (error) {
            console.error('Error getting user tickets:', error);
            throw error;
        }
    }

    async getWinningTicketsForPool(raffleId: number, poolIndex: number) {
        try {
            return await this.raffleContract.getWinningTicketsForPool(raffleId, poolIndex);
        } catch (error) {
            console.error('Error getting winning tickets:', error);
            throw error;
        }
    }

    async getSequenceFees() {
        try {
            return await this.raffleContract.getSequenceFees();
        } catch (error) {
            console.error('Error getting sequence fees:', error);
            throw error;
        }
    }

    async getTicketInfo(raffleId: number, ticketId: number) {
        try {
            const info = await this.raffleContract.getTicketInfo(raffleId, ticketId);
            return {
                owner: info.owner,
                prizeShare: info.prizeShare,
                purchasePrice: info.purchasePrice
            };
        } catch (error) {
            console.error('Error getting ticket info:', error);
            throw error;
        }
    }

    async getTicketPrice(raffleId: number, quantity: number) {
        try {
            return await this.raffleContract.getTicketPrice(raffleId, quantity);
        } catch (error) {
            console.error('Error getting ticket price:', error);
            throw error;
        }
    }

    async getSimulatedTicketPrice(ticketTokenQuantity: number, totalTickets: number, ticketsMinted: number, quantity: number) {
        try {
            return await this.raffleContract.getSimulatedTicketPrice(ticketTokenQuantity, totalTickets, ticketsMinted, quantity);
        } catch (error) {
            console.error('Error getting simulated ticket price:', error);
            throw error;
        }
    }
    // Helper method to parse events
    private parseEvent(receipt: ethers.ContractTransactionReceipt, eventName: string) {
        return receipt?.logs
            .filter((log: ethers.Log) => log.address === this.raffleContractAddress)
            .map((log: ethers.Log) => {
                try {
                    return this.raffleContract.interface.parseLog({
                        topics: log.topics,
                        data: log.data
                    });
                } catch (e) {
                    return null;
                }
            })
            .find((event: ethers.LogDescription | null) => event?.name === eventName);
    }
    
} 
