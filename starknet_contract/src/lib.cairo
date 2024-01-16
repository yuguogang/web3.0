#[starknet::contract]
mod Transactions {
    use core::traits::TryInto;
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
#[derive(Copy, Drop, Serde, starknet::Store)]
struct TransferStruct {
        sender:ContractAddress,
        receiver:ContractAddress,
        amount:felt252,
        message:felt252,
        timestamp:u64,
        keyword:felt252,
}

#[starknet::interface]
trait ITransactions<TContractState> {
    fn addToBlockchain(ref self: TContractState,receiver:ContractAddress,amount:felt252, message:felt252, keyword:felt252); 
    fn getAllTransactions(self: @TContractState) ->Span<TransferStruct>;
    fn getTransactionCount(self: @TContractState) -> u128;
}
    #[storage]
    struct Storage {
        transactions: LegacyMap::<u128, TransferStruct>,
        transactionCount:u128,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        receiver: ContractAddress,
        amount:felt252,
        message:felt252,
        keyword:felt252,
    }

    #[external(v0)]
    impl TransactionsImpl of ITransactions<ContractState> {

        fn addToBlockchain(ref self: ContractState,receiver:ContractAddress,amount:felt252, message:felt252, keyword:felt252) {
            let count:u128 = self.transactionCount.read() + 1;
            self.transactionCount.write(count);
            self.transactions.write(count,TransferStruct {sender:get_caller_address(),receiver,amount,message,timestamp:get_block_timestamp(),keyword});
            self.emit(Transfer { from: get_caller_address(), receiver: receiver,amount:amount,message:message,keyword:keyword });
        }
        fn getAllTransactions(self: @ContractState) ->Span<TransferStruct>{
            let mut transfers: Array<TransferStruct> = array![];
            let mut i:u128 = 1;
            loop {
                if(i<=self.transactionCount.read()) {
                    transfers.append(
                        self.transactions.read(i)
                    );
                } else {
                    break;
                }
                i+=1;
            };
            transfers.span()
        }
        fn getTransactionCount(self: @ContractState) -> u128{
            self.transactionCount.read()
        }
    }
}
