use core::array::SpanTrait;
use core::result::ResultTrait;
use core::option::OptionTrait;
use starknet_contract::ITransactionsSafeDispatcherTrait;
use core::traits::TryInto;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
use starknet_contract::MintableDispatcherTrait;
use starknet_contract::TransferStruct;
use starknet::ContractAddress;
use starknet::get_block_timestamp;
use starknet::contract_address_to_felt252;
use snforge_std::{declare, ContractClassTrait,start_prank,stop_prank,CheatTarget};

use starknet_contract::ITransactionsSafeDispatcher;
use starknet_contract::ITransactionsDispatcherTrait;
use openzeppelin::token::erc20::ERC20ABIDispatcher;
use starknet_contract::Mintable;
use starknet_contract::MintableDispatcher;
use core::array::ArrayTrait;
// #[starknet::contract]
// mod MyToken {
//     use openzeppelin::token::erc20::ERC20Component;
//     use starknet::ContractAddress;

//     component!(path: ERC20Component, storage: erc20, event: ERC20Event);

//     #[abi(embed_v0)]
//     impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
//     #[abi(embed_v0)]
//     impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
//     #[abi(embed_v0)]
//     impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
//     impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

//     #[storage]
//     struct Storage {
//         #[substorage(v0)]
//         erc20: ERC20Component::Storage
//     }

//     #[event]
//     #[derive(Drop, starknet::Event)]
//     enum Event {
//         #[flat]
//         ERC20Event: ERC20Component::Event
//     }

//     #[constructor]
//     fn constructor(ref self: ContractState) {
//         let name = 'MyToken';
//         let symbol = 'USDT';

//         self.erc20.initializer(name, symbol);
//     }

//     #[external(v0)]
//     fn mint(
//         ref self: ContractState,
//         recipient: ContractAddress,
//         amount: u256
//     ) {
//         // This function is NOT protected which means
//         // ANYONE can mint tokens
//         self.erc20._mint(recipient, amount);
//     }
// }
mod Accounts {
    use traits::TryInto;
    use starknet::{ContractAddress};
    fn admin() -> ContractAddress {
        'admin'.try_into().unwrap()
    }
    fn new_admin() -> ContractAddress {
        'new_admin'.try_into().unwrap()
    }
    fn bad_guy() -> ContractAddress {
        'bad_guy'.try_into().unwrap()
    }
}
// fn deploy_contract(name: felt252) -> ContractAddress {
//     let contract = declare(name);
//     contract.deploy(@ArrayTrait::new()).unwrap()
// }
fn deploy_contract(name: felt252,params:@Array::<felt252>) -> ContractAddress {
    let contract = declare(name);
    contract.deploy(params).unwrap()
}

#[test]
// #[available_gas = 3000000000000000]
fn test_addToBlockchain() {
    let usdt_address = deploy_contract('MyToken',@ArrayTrait::new());
    let usdt_dispatcher = ERC20ABIDispatcher { contract_address:usdt_address };
    let mut callData = array![contract_address_to_felt252(usdt_address)];
    let contract_address = deploy_contract('Transactions',@callData);
    let safe_dispatcher = ITransactionsSafeDispatcher { contract_address };
    let mint_dispatcher = MintableDispatcher { contract_address:usdt_address };
    start_prank(CheatTarget::All,Accounts::admin());
    mint_dispatcher.mint(Accounts::admin(),10000000);
    assert(usdt_dispatcher.balance_of(Accounts::admin()) == 10000000,'invalid sender balance!');
    safe_dispatcher.addToBlockchain(receiver:Accounts::bad_guy(),amount:30000,message:'hello',keyword:'hello');
    let bad_guy_balance = usdt_dispatcher.balance_of(Accounts::bad_guy());
    assert(bad_guy_balance == 30000,'invalid receiver balance!');
    let transactionCount:u128 = safe_dispatcher.getTransactionCount().unwrap();
    assert(transactionCount == 1,'invalid transactionCount!');
    stop_prank(CheatTarget::All);
    let transactions = safe_dispatcher.getAllTransactions();
    let t0 = transactions.unwrap().at(0);
    assert(*t0.sender == Accounts::admin(),'invalid transaction sender!');
    assert(*t0.receiver == Accounts::bad_guy(),'invalid transaction receiver!');
    assert(*t0.amount == 30000,'invalid transaction amount!');
}
