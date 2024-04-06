// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const nftContract = await hre.ethers.deployContract(
        "SHIFTWORK",
        [
            "0xC93f2Ca1bEd3a10aC3e1292C6bC78aA87e870F2f", // initial owner
            "0xC93f2Ca1bEd3a10aC3e1292C6bC78aA87e870F2f", //_shiftTokenAddress
            "0xC93f2Ca1bEd3a10aC3e1292C6bC78aA87e870F2f",
        ], //_shiftProofsAddress
        {}
    );
    const res = await nftContract.waitForDeployment();
    const nftAddress = res.target;
    console.log("Rentable contract deployed to:", nftAddress);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });