
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import { connect, disconnect } from '@argent/get-starknet'
import { useState, useEffect } from 'react'
import { Contract } from 'starknet'
import contractAbi from './abis/abi.json'
const contractAddress = "0x077e0925380d1529772ee99caefa8cd7a7017a823ec3db7c003e56ad2e85e300"

function App() {
  const [count, setCount] = useState(0)
  const [connection, setConnection] = useState();
  const [account, setAccount] = useState('');
  const [address, setAddress] = useState('');

  const [retrievedValue, setRetrievedValue] = useState('')

  const connectWallet = async() => {
    const connection = await connect({webWalletUrl:"https:web.argent.xyz"});
    if(connection && connection.isConnected) {
      setConnection(connection);
      setAccount(connection.account);
      setAddress(connection.selectedAddress);
    }
  }
  return (
    <>
      <div>
        <a href="https://vitejs.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={connectWallet}>
          count is {address}
        </button>
        <p>
          Edit <code>src/App.jsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
