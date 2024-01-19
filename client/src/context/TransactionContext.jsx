import React, { useEffect, useState } from "react";

import { connect, disconnect } from '@argent/get-starknet'
import { Contract, Provider, constants ,shortString,cairo} from 'starknet'
import { contractABI, contractAddress } from "../utils/constants";

export const TransactionContext = React.createContext();

const getStarknetContract = () => {
  const provider = new Provider({sequencer:{network:constants.NetworkName.SN_GOERLI}});
  const contract = new Contract(contractABI,contractAddress,provider);
  return contract;
}

export const TransactionProvider = ({ children }) => {
  // const [connectedAccount,setConnectedAccount] = useState("");
  const [currentAccount, setCurrentAccount] = useState('');
  const [account, setAccount] = useState('');
  const [formData, setFormData] = useState({addressTo:'',amount:'',keyword:'',message:''});
  const [isLoading, setIsLoading] = useState(false);
  const [transactionCount, setTransactionCount] = useState(localStorage.getItem('transactionCount'));
  const [transactions, setTransactions] = useState([]);
  const handleChange = (e, name) => {
    setFormData((prevState)=>({...prevState,[name]:e.target.value}));
  }

  const getAllTransactions= async()=> {
    try {
      const transactionContract = getStarknetContract();
      const availableTransactions = transactionContract.getAllTransactions();
      const structuredTransactions = availableTransactions.map((transaction)=>({
        addressTo:transaction.receiver,
        addressFrom:transaction.sender,
        timestamp:new Date(transaction.timestamp.toNumber()*1000).toLocaleString(),
        message:transaction.message,
        keyword:transaction.keyword,
        amount:parseInt(transaction.amount.low._hex)/(10**18)
      }));
      setTransactions(structuredTransactions);
      console.log(structuredTransactions);
    }catch (error) {
      console.log(error);
    }
    // try {
    //   if(!ethereum) return alert('Please install metamask');
    //   const transactionContract = getEthereumContract();
    //   const availableTransactions = await transactionContract.getAllTransactions();
    //   const structuredTransactions = availableTransactions.map((transaction)=>({
    //     addressTo:transaction.receiver,
    //     addressFrom:transaction.sender,
    //     timestamp:new Date(transaction.timestamp.toNumber()*1000).toLocaleString(),
    //     message:transaction.message,
    //     keyword:transaction.keyword,
    //     amount:parseInt(transaction.amount._hex)/(10**18)

    //   }));
    //   setTransactions(structuredTransactions);
    //   console.log(structuredTransactions);
    // } catch (error) {
    //   console.log(error);
    // }
  }
  const checkIfWalletIsConnected = async() => {
    try {
      const connection = await connect({modelMode:"neverAsk",webWalletUrl:"https:web.argent.xyz"});
      if(connection && connection.isConnected) {
        setAccount(connection.account);
        setCurrentAccount(connection.selectedAddress);
        getAllTransactions();
      } else {
              console.log('No accounts found');
            }
          } catch (error) {
            console.log(error);
            throw new Error("No starknet object.");
          }
    
    
    // try {
    //     if(!ethereum) return alert('Please install metamask');
    //     const accounts = await ethereum.request({method:'eth_accounts'});
    //     console.log(accounts);
    //     if(accounts.length > 0) {
    //       setCurrentAccount(accounts[0]);
          
    //       getAllTransactions();
    //     } else {
    //       console.log('No accounts found');
    //     }
    //   } catch (error) {
    //     console.log(error);
    //     throw new Error("No ethereum object.");
    //   }
  }
  const checkIfTransactionsExist = async()=> {
    try {
      const transactionContract = getStarknetContract();
      const transactionCount = await transactionContract.getTransactionCount();
      window.localStorage.setItem("transactionCount",transactionCount);

    } catch (error) {
        console.log(error);
        throw new Error("No starknet object.");
    }
    // try {
    //   const transactionContract = getEthereumContract();
    //   const transactionCount = await transactionContract.getTransactionCount();
    //   window.localStorage.setItem("transactionCount",transactionCount);

    // } catch (error) {
    //     console.log(error);
    //     throw new Error("No ethereum object.");
    // }
  }
  const connectWallet = async()=> {
    const connection = await connect({webWalletUrl:"https:web.argent.xyz"});
    if(connection && connection.isConnected) {
      setAccount(connection.account);
      setCurrentAccount(connection.selectedAddress);
    }
    // try {
    //   if(!ethereum) return alert('Please install metamask');
    //   const accounts = await ethereum.request({method:'eth_requestAccounts'});
    //   setCurrentAccount(accounts[0]);
    // } catch (error) {
    //   console.log(error);
    //   throw new Error("No ethereum object.");
    // }
  }
  const disConnectWallet = async()=> {
      await disconnect();
      setAccount(undefined);
      setCurrentAccount(undefined);
  }


  const sendTransaction = async() => {
    try {
      const{addressTo,amount,keyword,message} = formData;
      const parsedAmount = cairo.uint256(amount*10**18);
      const parsedKeyword = shortString.encodeShortString(keyword);
      const parsedMessage = shortString.encodeShortString(message);
      const contract = new Contract(contractABI,contractAddress,account);
      await contract.addToBlockchain(addressTo,parsedAmount,parsedMessage,parsedKeyword);
    }catch(error) {
      console.log(error.message);
    }
    
    // try {
    //   if(!ethereum) return alert('Please install metamask');
    //   const{addressTo,amount,keyword,message} = formData;
    //   const transactionContract = getEthereumContract();
    //   const parsedAmount = ethers.utils.parseEther(amount);
    //   await ethereum.request({
    //     method:'eth_sendTransaction',
    //     params:[{
    //       from:currentAccount,
    //       to:addressTo,
    //       gas:'0x5208',  //21000 GWEI
    //       value:parsedAmount._hex,
    //     }]
    //   });

    //   const transactionHash = await transactionContract.addToBlockchain(addressTo,parsedAmount,message,keyword);

    //   setIsLoading(true);
    //   console.log(`Loading - ${transactionHash.hash}`);
    //   await transactionHash.wait();
    //   setIsLoading(false);
    //   console.log(`Success - ${transactionHash.hash}`);

    //   const transactionCount = await transactionContract.getTransactionCount();
    //   setTransactionCount(transactionCount.toNumber());
    // } catch (error) {
    //   console.log(error);
    //   throw new Error("No ethereum object.");
    // }
  }
  useEffect(()=>{
    checkIfWalletIsConnected();
    checkIfTransactionsExist();
  },[]);
  return (
    <TransactionContext.Provider
      value={{
        disConnectWallet,connectWallet,currentAccount,formData,setFormData,handleChange,sendTransaction,transactions
      }}
    >
      {children}
    </TransactionContext.Provider>
  );
};