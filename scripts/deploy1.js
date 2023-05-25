const BinBin = artifacts.require("BinBins");

module.exports = async function (deployer) {
  await deployer.deploy(BinBin );
  const instance = await BinBin .deployed();
  let BinBinAddress = await instance.address;

   let config = "export const BinBinAddress = " + BinBinAddress;

  console.log("Address = ", BinBinAddress);

    let data = JSON.stringify(config);
 
   fs.writeFileSync('config.js', JSON.parse(data)); 
}