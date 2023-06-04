import React, { useState, useEffect, Fragment } from "react";
import { Button, Form, Input, InputNumber } from "antd";

import NFTImg from "./splash.png"; 
import StoryCover from "./ms-os10.jpg"; 
import CellsComponent from "./CellsComponent";
import { keccak256 } from "ethers/lib/utils";

function IntroPage(props) {

    const [mintSection, setMintSection] = useState('');
    const [displaySection, setDisplaySection] = useState('');
    const [typeMinted, setTypeMinted] = useState('default');
    //const [owner, setOwner] = useState(null);

    const startDateString = "05 June 2023 14:00 GMT";
    const endDateString = "03 July 2023 14:00 GMT";
    const snapshotDate = "29 May 2023 14:00 GMT";
    const startDateUnix = 1685973600; // 05 June 2023
    const endDateUnix = 1688392800; // 03 July 2023

    const wrongNetworkHTML = <Fragment>You are on the wrong network. Please switch to mainnet on your web3 wallet and refresh the page.<br /><br/></Fragment>;

    const offlineHTML = <Fragment>
    [In order to mint an NFT, you need to  have a web3/Ethereum-enabled browser and connect it (see top right of the page). Please download
      the <a href="https://metamask.io">MetaMask Chrome extension</a> or open in an Ethereum-compatible browser.] <br />
      <br />
    </Fragment>;

    // Not being used in the interface but keeping it in here for future
    /*function withdrawETH() {
      props.withdrawETH();
    }*/

    function mintDeluxeNFT() {
      console.log('minting deluxe NFT');
      setDisplaySection('');
      setTypeMinted('deluxe');
      props.mintDeluxeNFT();
    }

    function mintNFT() {
      console.log('minting NFT');
      setDisplaySection('');
      setTypeMinted('default');
      props.mintNFT();
    }

    function claim() {
      console.log("claim!");
      props.claim(props.tree.getHexProof(keccak256(props.address)));
    }

    useEffect(() => {
        if(typeof props.address !== 'undefined' && props.NFTSigner !== null && props.tree !== null && props.injectedChainId === props.hardcodedChainId) {

          console.log(props.address.toLowerCase());
          let disabled = true; 
          var unix = Math.round(+new Date()/1000);
          if(unix >= startDateUnix) { disabled = false; } 
          if(unix >= endDateUnix) { disabled = true; } 

          let claimHTML = <Fragment>
          </Fragment>

          // verify is address is in the tree
          const hashedLeaf = keccak256(props.address);
          const proof = props.tree.getHexProof(hashedLeaf);
          const root = props.tree.getHexRoot();
          const inTree = props.tree.verify(proof, hashedLeaf, root);

          if(inTree) {
            claimHTML = <Fragment>
              <br />
              <Button type="primary" size={"medium"} disabled={disabled} loading={props.minting} onClick={claim}>
                Claim Your Deluxe Daisychain. (Free)
              </Button>
              <br />
              <br />
              Thanks to your loyalty, you are eligible to claim one free daisychain whenever you want! Thank you for the support! <br />
              </Fragment>
 
              if(props.alreadyClaimed == true) {
                claimHTML = <Fragment>
                  <br />
              <Button type="primary" size={"medium"} disabled={true} loading={props.minting} onClick={claim}>
                Claim Your Deluxe Daisychain. (Free)
              </Button>
              <br />
              <br />
              Thanks to your loyalty, you are eligible to claim one free daisychain whenever you want! Thank you for the support! (You've already claimed a free Daisychain). <br />
              </Fragment>
              }
          }

          let mintButton;
          let disabledDeluxeMint = disabled;
          // todo: automatically enable if sold out?
          mintButton = <Button type="primary" size={"medium"} disabled={disabledDeluxeMint} loading={props.minting} onClick={mintDeluxeNFT}>
            Mint Deluxe Daisychain (0.055 ETH)
          </Button>

          const newMintHTML = <Fragment>
            {displaySection}
            <h3>[] Deluxe Generative Daisychains</h3>
            Limited supply! First come, first serve. 96 are buyable (0.055 ETH. ~$100).<br />
            They are animated and rotate (click to animate!).<br />
            <br />
            {mintButton}
            <br />
            {claimHTML}
            <br />
            <h3>[] Default Generative Daisychains</h3>
            Generative open edition (0.016 ETH. ~$30). Thus, unlimited supply for the 4 week campaign.
            <br />
            They do not rotate.<br />
            <br />
            <Button type="primary" size="medium" disabled={disabled} loading={props.minting} onClick={mintNFT}>
              Mint a Default Daisychain (0.016 ETH)
            </Button>
            <br />
            <br />
            By minting, you agree to the <a href="https://github.com/Untitled-Frontier/tlatc/blob/master/TOS_PP.pdf">Terms of Service</a>.
            <br />
            <br />
            
          </Fragment>

          setMintSection(newMintHTML);
        }
    }, [props.address, props.NFTSigner, props.minting, props.tree, props.vm, props.localNFTAddress, props.alreadyClaimed, displaySection]);

    useEffect(() => {
      if(props.injectedChainId !== props.hardcodedChainId && props.injectedChainId !== null) {
        console.log('wrong network');
        setMintSection(wrongNetworkHTML);
      } else if(props.injectedChainId == null) {
        setMintSection(offlineHTML);
      }
    }, [props.hardcodedChainId, props.NFTSigner]);


    useEffect(() => {
      if(props.mintedSVG !== null) {
        let header = <h2>Your new Default Daisychain has been minted!</h2>;
        if(typeMinted === 'deluxe') {
          header = <h2>Your new Deluxe Daisychain has been minted! Click center to rotate!</h2>;
        }
        setDisplaySection(
          <Fragment>
            {header}
            <CellsComponent svg={props.mintedSVG}/> <br />
            To interact with the NFT: to view it, to transfer it, and to see other NFTs, head to <a href="https://opensea.io/collection/daisychains-life-in-every-breath" target="_blank">OpenSea</a>. 
            It's a platform to view and interact with NFTs, including the Daisychains. It will be in your profile. 
            If you choose to mint another, new Daisychain, it will update to display your new one. All Daisychains, however, are recorded forever
            on the Ethereum blockchain, and viewable in OpenSea.<br />
            <br />
          </Fragment>
        );
      }
    }, [props.mintedSVG]);

    return (
        <div className="App" style={{textAlign:"justify"}}> 
        <br />
        <img src={NFTImg} alt="Daisychains: Life In Every Breath" style={{display:"block", marginLeft:"auto", marginRight: "auto", maxWidth:"100%"}}/> <br />
        From <b>{startDateString} until {endDateString}</b> (a limited time only), fans can mint or claim onchain, generative art flowers from the Logged Universe story, <a href="https://www.untitledfrontier.studio/blog/logged-universe-5-ms-os" target="_blank">"MS-OS" by Andy Tudhope</a> with 50% of the proceeds going to the writer!
        <br />
        <br />
        {/* MINT SECTION */}
        <div className="section">
        {mintSection}
        </div>
        <h2>[] DETAILS </h2>
        Each Daisychain contains 32 different randomly generated variables that inform and change its appearance. Each Daisychain is thus unique, lending itself to different, striking variations of colour, shapes, and patterns. 
        It's all onchain, generated through SVG and thus will exist as long as Ethereum does.
        <br />
        <br />
        The collection is divided into two variations: a limited supply, deluxe Daisychain, and an open edition default Daisychain. The deluxe Daisychains rotate and are sold as first come, first serve.
        To be eligible to claim a deluxe Daisychain for free, you would have had to have owned an NFT from all the previous 4 Logged Universe stories combined by {snapshotDate}. You can claim it any time during the campaign.
        After the campaign period, no new Daisychains can be minted or claimed. The deluxe Daisychains are best viewed on a browser that supports hardware rendering (eg, Chrome or Brave).
        <br />
        <br />
        The components that make up the Daisychains are licensed under <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>. Thus, you are free to use the NFTs as you wish. <a href="https://github.com/Untitled-Frontier/ug">The code is available on Github.</a>
        <br />
        <br />
        You can view already minted "Daisychains" on <a href="https://opensea.io/collection/daisychains-life-in-every-breath" target="_blank">OpenSea</a>.
        <br />
        <br />
        <h2> [] MS-OS </h2>
        These daisychains are collectible memorabilia from the fifth story in the Logged Universe: <a href="https://www.untitledfrontier.studio/blog/logged-universe-5-ms-os" target="_blank">"MS-OS" by Andy Tudhope</a>.
        <br />
        <br />
        <i> A simulated soul, finding themselves back in the real world, in Anchor City, remains confused about their place in all things. Blurring realities again, they undergo a new journey.</i>
        <br />
        <br />
        <img src={StoryCover} alt="MS-OS Cover" style={{display:"block", marginLeft:"auto", marginRight: "auto", maxWidth:"100%"}}/> <br />
        The cover art is by Zsuzsanna Tasi is ALSO available to collect <a href="https://foundation.app/collection/ms-os">on Foundation</a>. 100% of the proceeds go to her.
        <br />
        <br />
        You can listen to the story here, narrated by Sam Yeow: <br />
        <br />
        <iframe width="560" height="315" src="https://www.youtube.com/embed/yIT5j5Y7mBg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
        <br />
        <br />
        <br />
        <br />
        </div>
    );
}

export default IntroPage
