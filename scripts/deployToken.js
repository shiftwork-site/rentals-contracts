// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const erc20TokenContract = await hre.ethers.deployContract(
        "SHIFTTOKEN",
        [
            "0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22", // initial owner
        ],
        {}
    );
    const res2 = await erc20TokenContract.waitForDeployment();
    const erc20TokenAddress = res2.target;
    console.log("ERC20 contract deployed to:", erc20TokenAddress);
}
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
