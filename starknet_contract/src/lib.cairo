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
    use openzeppelin::token::erc20::ERC20Component;
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
        tokenAddress:ContractAddress,
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
      #[constructor]
    fn constructor(ref self: ContractState, _tokenAddress:ContractAddress) {
        self.tokenAddress.write(_tokenAddress);
    }

    #[external(v0)]
    impl TransactionsImpl of super::ITransactions<ContractState> {
  

        fn addToBlockchain(ref self: ContractState,receiver:ContractAddress,amount:u256, message:felt252, keyword:felt252) {
            let eth_contract: ContractAddress = self.tokenAddress.read();
            let erc20abi = ERC20ABIDispatcher{contract_address:eth_contract};
            assert(erc20abi.approve(receiver,amount),'Insuffcient ETH');
            erc20abi.transfer(receiver,amount);
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
#[starknet::interface]
trait Mintable<TContractState> {
   fn mint(
        ref self: TContractState,
        recipient: ContractAddress,
        amount: u256
    ) ;
}
#[starknet::contract]
mod MyToken {
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let name = 'MyToken';
        let symbol = 'USDT';

        self.erc20.initializer(name, symbol);
    }

    #[external(v0)]
    impl MintImpl of super::Mintable<ContractState> {
    fn mint(
        ref self: ContractState,
        recipient: ContractAddress,
        amount: u256
    ) {
        // This function is NOT protected which means
        // ANYONE can mint tokens
        self.erc20._mint(recipient, amount);
    }
    }
}
