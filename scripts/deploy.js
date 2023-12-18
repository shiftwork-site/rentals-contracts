// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const proofContract = await hre.ethers.deployContract("SHIFTPROOFS", ["0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86"], {});
  const res3 = await proofContract.waitForDeployment();
  const proofAddress = res3.target;
  console.log("Proof contract deployed to:", proofAddress);

  const erc20TokenContract = await hre.ethers.deployContract("SHIFTTOKEN", ["SHIFTTOKEN", "SHIFT"], {});
  const res2 = await erc20TokenContract.waitForDeployment();
  const erc20TokenAddress = res2.target;
  console.log("ERC20 contract deployed to:", erc20TokenAddress);


  // const tempErc20 = "0x28D4Ec0d785076E43371B0F454111e98e4890D68";
  const nftContract = await hre.ethers.deployContract("SHIFTRENTALS", ["SHIFTRENTALS", "SRT", "0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22", 1, erc20TokenAddress, proofAddress], {});
  const res = await nftContract.waitForDeployment();
  const nftAddress = res.target;
  console.log("Rentable contract deployed to:", nftAddress);

  await erc20TokenContract.updateAllowedWhitelistContract(nftAddress);
  console.log("Rentable contract can now update whitelist for tokens:", nftAddress);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
