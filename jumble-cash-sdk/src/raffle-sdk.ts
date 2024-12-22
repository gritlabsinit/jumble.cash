import { ethers } from 'ethers';
import { RaffleABI } from './abi/Raffle';
import { ERC20ABI } from './abi/ERC20';

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

// First, let's define an interface for the log structure
interface RaffleLog {
    address: string;
    topics: string[];
    data: string;
}

interface SequenceNumberRequestedEvent {
    raffleId: bigint;
    sequenceNumber: bigint;
}

export class RaffleSdk {
    private provider: ethers.Provider;
    private signer: ethers.Signer;
    private raffleContract: ethers.Contract;
    private tokenContract: ethers.Contract;
    private raffleContractAddress: string;

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

            // Parse the RaffleCreated event
            const event = receipt?.logs
                .filter((log: RaffleLog) => log.address === this.raffleContractAddress)
                .map((log: RaffleLog) => {
                    try {
                        return this.raffleContract.interface.parseLog({
                            topics: log.topics,
                            data: log.data
                        });
                    } catch (e) {
                        return null;
                    }
                })
                .find((event: ethers.LogDescription | null) => event?.name === 'RaffleCreated');

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
            console.error('Error creating raffle:', error);
            throw error;
        }
    }

    async buyTickets(raffleId: number, quantity: number): Promise<TicketsPurchasedEvent | null> {
        try {
            const raffleInfo = await this.raffleContract.getRaffleInfo(raffleId);
            const totalCost = raffleInfo.ticketTokenQuantity * BigInt(quantity);

            // Approve tokens first
            const approveTx = await this.tokenContract.approve(
                await this.raffleContract.getAddress(),
                totalCost
            );
            await approveTx.wait();

            // Buy tickets
            const tx = await this.raffleContract.buyTickets(raffleId, quantity);
            const receipt = await tx.wait();

            // Parse the TicketsPurchased event
            const event = receipt?.logs
                .filter((log: RaffleLog) => log.address === this.raffleContractAddress)
                .map((log: RaffleLog) => {
                    try {
                        return this.raffleContract.interface.parseLog({
                            topics: log.topics,
                            data: log.data
                        });
                    } catch (e) {
                        return null;
                    }
                })
                .find((event: ethers.LogDescription | null) => event?.name === 'TicketsPurchased');

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
            console.error('Error buying tickets:', error);
            throw error;
        }
    }

    async finalizeRaffle(raffleId: number): Promise<SequenceNumberRequestedEvent | null> {
        try {
            const tx = await this.raffleContract.finalizeRaffle(raffleId, {
                value: ethers.parseEther("0.0001")
            });
            const receipt = await tx.wait();

            // Parse SequenceNumberRequested event
            const event = receipt?.logs
                .filter((log: RaffleLog) => log.address === this.raffleContractAddress)
                .map((log: RaffleLog) => {
                    try {
                        return this.raffleContract.interface.parseLog({
                            topics: log.topics,
                            data: log.data
                        });
                    } catch (e) {
                        return null;
                    }
                })
                .find((event: ethers.LogDescription | null) => event?.name === 'SequenceNumberRequested');

            if (!event) {
                console.warn('SequenceNumberRequested event not found in transaction receipt');
                return null;
            }

            return {
                raffleId: event.args[0],
                sequenceNumber: event.args[1]
            };
        } catch (error) {
            console.error('Error finalizing raffle:', error);
            throw error;
        }
    }

    async claimPrize(raffleId: number): Promise<PrizeClaimedEvent | null> {
        try {
            const tx = await this.raffleContract.claimPrize(raffleId);
            const receipt = await tx.wait();

            // Parse the PrizeClaimed event
            const event = receipt?.logs
                .filter((log: RaffleLog) => log.address === this.raffleContractAddress)
                .map((log: RaffleLog) => {
                    try {
                        return this.raffleContract.interface.parseLog({
                            topics: log.topics,
                            data: log.data
                        });
                    } catch (e) {
                        return null;
                    }
                })
                .find((event: ethers.LogDescription | null) => event?.name === 'PrizeClaimed');

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
            console.error('Error claiming prize:', error);
            throw error;
        }
    }

    // // Helper method to parse events
    // private parseEvent(receipt: ethers.ContractTransactionReceipt, eventName: string) {
    //     return receipt?.logs
    //         .filter((log: RaffleLog) => log.address === this.raffleContractAddress)
    //         .map((log: RaffleLog) => {
    //             try {
    //                 return this.raffleContract.interface.parseLog({
    //                     topics: log.topics,
    //                     data: log.data
    //                 });
    //             } catch (e) {
    //                 return null;
    //             }
    //         })
    //         .find((event: ethers.LogDescription | null) => event?.name === eventName);
    // }

    async refundTicket(raffleId: number, ticketId: number) {
        try {
            const tx = await this.raffleContract.refundTicket(raffleId, ticketId);
            const receipt = await tx.wait();
            return receipt;
        } catch (error) {
            console.error('Error refunding ticket:', error);
            throw error;
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
                minTicketsRequired: info.minTicketsRequired,
                totalSold: info.totalSold,
                availableTickets: info.availableTickets,
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
} 