import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import {TransactionProvider}  from './context/TransactionContext'
ReactDOM.createRoot(document.getElementById('root')).render(
  <TransactionProvider>
    <React.StrictMode>
      <App />
    </React.StrictMode>
  </TransactionProvider>
);

// import React from 'react'
// import ReactDOM from 'react-dom/client'
// import App from './App.jsx'
// import './index.css'

// ReactDOM.createRoot(document.getElementById('root')).render(
//   <React.StrictMode>
//     <App />
//   </React.StrictMode>,
// )
