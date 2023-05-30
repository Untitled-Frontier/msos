const generator = require('./helpers/merkle_generator.js');

async function main() {
    
    const tree = await generator();
    const root = tree.getHexRoot();
    console.log("Generated merkle root: ", root)

    const C = await ethers.getContractFactory("Collection");
    // name, symbol, recipient, startDate, endDate, merkle root
    // 1685989426 == June 5 2022 (keep it a few days for testing)
    //const c = await C.deploy("Capsules of All Our Lives", "COAOL", "0xE221A618e4A52ABF51Dd99406CfbBB32b41BBa06", '100', '1664908534', root);
    const c = await C.deploy("Daisychains: Life In Every Breath", "LIEB", "0xaF69610ea9ddc95883f97a6a3171d52165b69B03", '100', '1685989426', root, {gasLimit: "8000000"});
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