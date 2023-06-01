const generator = require('./helpers/merkle_generator.js');

// Split: 0x0EC164CADBb42f366D65E9dfd056c0cC2BAB02a9

async function main() {
    
    const tree = await generator();
    const root = tree.getHexRoot();
    console.log("Generated merkle root: ", root)

    const C = await ethers.getContractFactory("Collection");
    // name, symbol, recipient, startDate, endDate, merkle root
    const c = await C.deploy("Daisychains: Life In Every Breath", "DLIEB", "0x0EC164CADBb42f366D65E9dfd056c0cC2BAB02a9", '1685973600', '1688392800', root, {maxFeePerGas: ethers.utils.parseUnits("70", "gwei"), gasLimit: "10000000"});
    const cd = await c.deployed();
    const cAddress = await c.address;
    console.log("MSOS deployed to: ", cAddress);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });