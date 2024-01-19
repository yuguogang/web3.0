use starknet::ContractAddress;
#[starknet::interface]
trait ITransactions<TContractState> {
    fn addToBlockchain(ref self: TContractState,receiver:ContractAddress,amount:u256, message:felt252, keyword:felt252); 
    fn getAllTransactions(self: @TContractState) ->Span<TransferStruct>;
    fn getTransactionCount(self: @TContractState) -> u128;
}
#[derive(Copy, Drop, Serde, starknet::Store)]
struct TransferStruct {
        sender:ContractAddress,
        receiver:ContractAddress,
        amount:u256,
        message:felt252,
        timestamp:u64,
        keyword:felt252,
}

#[starknet::contract]
mod Transactions {
    use core::option::OptionTrait;
    use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
    use core::traits::TryInto;
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use starknet::contract_address_try_from_felt252;
    use super::TransferStruct;
    use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;

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
        amount:u256,
        message:felt252,
        keyword:felt252,
    }


    #[external(v0)]
    impl TransactionsImpl of super::ITransactions<ContractState> {

        fn addToBlockchain(ref self: ContractState,receiver:ContractAddress,amount:u256, message:felt252, keyword:felt252) {
            let eth_contract: ContractAddress = contract_address_try_from_felt252(0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7).unwrap();
            assert(ERC20ABIDispatcher{contract_address:eth_contract}.transfer(receiver,amount),'Insuffcient ETH');
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
