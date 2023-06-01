const generator = require('./helpers/merkle_generator.js');


async function main() {
    
    const tree = await generator();
    const root = tree.getHexRoot();
    console.log("Generated merkle root: ", root)

    const C = await ethers.getContractFactory("Collection");
    // name, symbol, recipient, startDate, endDate, merkle root
    const c = await C.deploy("Daisychains: Life In Every Breath", "LIEB", "0xaF69610ea9ddc95883f97a6a3171d52165b69B03", '100', '2627308000', root, {gasLimit: "50000000"});
    const cd = await c.deployed();
    console.log(cd);
    const id = await c.newlyMinted();
    const ig = await cd.tokenURI(id);
    const i = await cd.generateImage(id);
    const t = await cd.generateTraits(id);

    console.log(t.toString());
    console.log(id.toString());
    console.log(i.toString());
    console.log(ig.toString());

    const cAddress = await c.address;
    console.log("MSOS deployed to: ", cAddress);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });