import React, { useState, useEffect, Component } from 'react';
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import 'antd/dist/antd.css';
import { ethers } from "ethers";
import "./App.css";
import { Account } from "./components"

import IntroPage from './components/IntroPage.js';

import { usePoller } from "./hooks";

import Transactor from "./helpers/Transactor.js"; 

import generateTree from "./helpers/merkle_generator.js";


import { VM } from '@ethereumjs/vm';
import { Chain, Common, Hardfork } from '@ethereumjs/common';
import { Account as AccountVM, Address } from '@ethereumjs/util';
import { Transaction } from '@ethereumjs/tx';

// Artifacts
import NFTJson from "./contracts/Collection.json";
import { Interface } from 'ethers/lib/utils';

function App() {
  let BigInt;
  if (typeof BigInt === 'undefined') { BigInt = require('big-integer'); } // note: is this still even necessary?

  /* Universal State*/
  const [address, setAddress] = useState();
  const [injectedProvider, setInjectedProvider] = useState();
  const [minting, setMinting] = useState(false); // whether something is minting or not
  const [alreadyClaimed, setAlreadyClaimed] = useState(false); // whether something is minting or not

  // chain ids (used as proxy for being connect to a provider)
  //const [tokenId, setTokenId] = useState(0); // token Id to display
  const [injectedChainId, setInjectedChainId] = useState(null);
  const [hardcodedChainId, setHardcodedChainId] = useState(null); // set it manually

  // for rendering imagery in the browser
  const [vm, setVM] = useState(null);
  const [localNFTAddress, setLocalNFTAddress] = useState(null);
  const [SVG, setSVG] = useState(null);
  const [mintedSVG, setMintedSVG] = useState(null);

  let NFTAddress = "0x0E4447AeCE6d71062c14815F0fC557F29a62Fa19"; // mainnet

  // for local testing:
  //NFTAddress = "0x600a4446094C341693C415E6743567b9bfc8a4A8"; //localhost
  //NFTAddress = "0xdc742b93b9aa0520188f18c88a9d4c8edfd01c1a"; //Sepolia

  let dxPrice = "0.055"; // ~$100
  let dfPrice = "0.016"; // ~$30

  const [NFTSigner, setNFTSigner] = useState(null);
  const [tree, setTree] =  useState(null);

  // NOTE: Currently not being used in Transactor, but keeping it in the code in case I want to turn it back on.
  // Currently, it's expected that the web3 provider sets it (eg, MetaMask fills it in).
  // const gasPrice = useGasPrice("fast"); 
  const gasPrice = 0;

  usePoller(()=>{pollInjectedProvider()},1999);

  async function pollInjectedProvider() {
      if(!injectedChainId) {
          if(injectedProvider && injectedProvider.network) {
              const id = await injectedProvider.network.chainId;
              setInjectedChainId(id);

              // comment out line for local or prod
              setHardcodedChainId(1); // mainnet
              //setHardcodedChainId(5); // goerli
              //setHardcodedChainId(id); // local (uses injectedProvider)
              //setHardcodedChainId(11155111); //sepolia
          }
      }
  } 
  
  // load signers if there's an injected provider
  useEffect(() => {
    async function loadSigners() {
      if(injectedChainId !== null) {
        const signer = await injectedProvider.getSigner();
        const NFTSigner = new ethers.Contract(NFTAddress, NFTJson.abi, signer);
        setNFTSigner(NFTSigner);

        // also load the merkle tree
        const tree =  await generateTree();
        setTree(tree);

        // start and deploy an in-browser version of the contract for rendering/drawing
        // start the browser vm 
        // instantiate an account from person address
        const c = new Common({ chain: Chain.Mainnet, hardfork: Hardfork.Merge });
        const vm = await VM.create({c}); 
        const pk = Buffer.from(
          '1122334455667788112233445566778811223344556677881122334455667788',
          'hex'
        );
        const account = AccountVM.fromAccountData({
          balance: ethers.utils.parseEther('100').toHexString() // 100 eth
        });

        // deploy contract
        const vmAddress = Address.fromPrivateKey(pk);
        await vm.stateManager.putAccount(vmAddress, account);
        const NFTFactory = new ethers.ContractFactory(NFTJson.abi, NFTJson.bytecode);
        // details don't matter for parameters since it only uses it draw IN browser
        const deployTx = NFTFactory.getDeployTransaction("TEST COLLECTION", "T", "0xaF69610ea9ddc95883f97a6a3171d52165b69B03", '100', '2627308000', "0x5a205b661dc03e3b33329ec05c331ddb579d0a146b5a14e68d88d5eafaaa5d15");
        const txData = {
          value: 0,
          gasLimit: 30_000_000,
          gasPrice: 7,
          data: deployTx.data,
          nonce: account.nonce,
        };
        const tx = Transaction.fromTxData(txData).sign(pk);
        const deploymentResult = await vm.runTx({ tx });
        console.log(deploymentResult);
        if (deploymentResult.execResult.exceptionError) {
          throw deploymentResult.execResult.exceptionError;
        }

        setVM(vm);
        setLocalNFTAddress(deploymentResult.createdAddress);
      }
    }
    loadSigners();
  }, [injectedChainId]);

  async function generateSVGFromTokenID(tokenId, deluxe) {
    const iface = new Interface(NFTJson.abi);
    const calldata = iface.encodeFunctionData("generateImageFromTokenIDAndDeluxe", [tokenId, deluxe]);
    const renderResult = await vm.evm.runCall({
      to: localNFTAddress,
      caller: localNFTAddress,
      origin: localNFTAddress,
      data: Buffer.from(calldata.slice(2), 'hex')
    });

    const results = ethers.utils.defaultAbiCoder.decode(
      ['string'],
      renderResult.execResult.returnValue
    );

    return results;
  }

  async function mintDeluxeNFT() {
    let val = ethers.utils.parseEther(dxPrice);
    const tx = Transactor(injectedProvider, gasPrice);
    setMinting(true);
    tx(NFTSigner.functions.mintDeluxe({value: val}), async function (update) {
      /*Used for testing UI*/
      // await new Promise(resolve => setTimeout(resolve, 5000));
      console.log(update);
      console.log(update.eventCode);
      if(update.eventCode === "txConfirmed" || update.confirmations === 1) {
        const txResponse = await injectedProvider.getTransaction(update.hash);
        console.log(txResponse);
        const receipt = await txResponse.wait();
        console.log(receipt);
        const tokenId = receipt.logs[0].topics[3];
        const svg = await generateSVGFromTokenID(tokenId, true);
        setMintedSVG(svg);
        setMinting(false);
      }

      /* if user denies tx */
      if(update.code !== undefined) {
        if(update.code === 4001) {
          setMinting(false);
        }

        /* if too high gas limit */
        if(update.code === "UNPREDICTABLE_GAS_LIMIT") {
          setMinting(false);
        }
      }
    });
  }

  // Not being used in the interface but keeping it in here. Was used in testing goerli.
  /*async function withdrawETH() {
    let val = ethers.utils.parseEther(randomPrice);
    const tx = Transactor(injectedProvider, gasPrice);
    setMinting(true);
    tx(NFTSigner.functions.withdrawETH(), async function (update) {
      /*Used for testing UI
      // await new Promise(resolve => setTimeout(resolve, 5000));
      console.log(update);
      console.log(update.eventCode);
      if(update.eventCode === "txConfirmed" || update.confirmations === 1) {
        const txResponse = await injectedProvider.getTransaction(update.hash);
        console.log(txResponse);
        const receipt = await txResponse.wait();
        console.log(receipt);
        setMinting(false);
      }

      /* if user denies tx 
      if(update.code !== undefined) {
        if(update.code === 4001) {
          setMinting(false);
        }

        /* if too high gas limit
        if(update.code === "UNPREDICTABLE_GAS_LIMIT") {
          setMinting(false);
        }
      }
    });
  }*/

  async function mintNFT() {
    let val = ethers.utils.parseEther(dfPrice);
    const tx = Transactor(injectedProvider, gasPrice);
    setMinting(true);
    tx(NFTSigner.functions.mint({value: val}), async function (update) {
      /*Used for testing UI*/
      // await new Promise(resolve => setTimeout(resolve, 5000));
      console.log(update);
      console.log(update.eventCode);
      if(update.eventCode === "txConfirmed" || update.confirmations === 1) {
        const txResponse = await injectedProvider.getTransaction(update.hash);
        console.log(txResponse);
        const receipt = await txResponse.wait();
        console.log(receipt);
        const tokenId = receipt.logs[0].topics[3];
        const svg = await generateSVGFromTokenID(tokenId, false);
        setMintedSVG(svg);
        setMinting(false);
      }

      /* if user denies tx */
      if(update.code !== undefined) {
        if(update.code === 4001) {
          setMinting(false);
        }

        /* if too high gas limit */
        if(update.code === "UNPREDICTABLE_GAS_LIMIT") {
          setMinting(false);
        }
      }
    });
  }

  async function claim(proof) {
    const tx = Transactor(injectedProvider, gasPrice);
    setMinting(true);
    console.log('proof', proof);
    tx(NFTSigner.functions.loyalMint(proof), async function (update) {
      /*Used for testing UI*/
      // await new Promise(resolve => setTimeout(resolve, 5000));
      console.log(update);
      console.log(update.eventCode);
      console.log(update.code);
      if(update.eventCode === "txConfirmed" || update.confirmations === 1) {
        const txResponse = await injectedProvider.getTransaction(update.hash);
        console.log(txResponse);
        const receipt = await txResponse.wait();
        console.log(receipt);
        const tokenId = receipt.logs[0].topics[3];
        const svg = await generateSVGFromTokenID(tokenId, true);
        setMintedSVG(svg);
        setMinting(false);
      } 

      if(update.code !== undefined) {
        /* if user denies tx */
        if(update.code === 4001) {
          setMinting(false);
        }

        // already claimed
        if(update.code === -32603) {
          setMinting(false);
        }

        /* if too high gas limit then it means that it was already claimed */
        if(update.code === "UNPREDICTABLE_GAS_LIMIT") {
          setMinting(false);
          setAlreadyClaimed(true);
        }
      }
    });
  }

  return (
      <div>
      <Account
        address={address}
        setAddress={setAddress}
        injectedProvider={injectedProvider}
        setInjectedProvider={setInjectedProvider}
      />
      <Switch>
      <Route exact path="/">
          <IntroPage
            address={address}
            NFTSigner={NFTSigner}
            injectedChainId={injectedChainId}
            hardcodedChainId={hardcodedChainId}
            vm={vm}
            localNFTAddress={localNFTAddress}
            mintNFT={mintNFT}
            mintDeluxeNFT={mintDeluxeNFT}
            claim={claim}
            alreadyClaimed={alreadyClaimed}
            mintedSVG={mintedSVG}
            minting={minting}
            dxPrice={dxPrice}
            dfPrice={dfPrice}
            tree={tree}
          />
      </Route>
      </Switch>
      </div>
  );
}

class AppRoutes extends Component {
  render() {
    return (
      <Router>
        <Switch>        
          <Route path='/:page'>
            <App />
          </Route>
          <Route exact path='/'>
            <App />
          </Route>
        </Switch>
      </Router>
    )
  }
}

export default AppRoutes;
