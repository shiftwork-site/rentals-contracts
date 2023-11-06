const { ethers } = require("hardhat");

describe("SHIFTRENTALS", async function () {
  let nftContractFactory;
  let nftContract;
  let addr1;
  let addr2;
  let addr3;
  let addr4;

  beforeEach(async () => {
    [addr1, addr2, addr3, addr4] = await ethers.getSigners();
    nftContractFactory = await hre.ethers.getContractFactory('SHIFTRENTALS');
    nftContract = await hre.ethers.deployContract("SHIFTRENTALS", ["SHIFTRENTALS", "SRT", addr1.address, 1], {});
    await nftContract.waitForDeployment();
  });

  it("should  mint successfully", async () => {
    await nftContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    expect(await nftContract.nextTokenIdToMint()).to.equal("1");
    await nftContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    expect(await nftContract.nextTokenIdToMint()).to.equal("2");
    console.log(await nftContract.tokenURI(0));
  });

  it("should set user successfully, but expired date", async () => {
    const amountToSend = ethers.parseEther("0.1");  // e.g., 0.1 ETH
    await nftContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    // await nftContract.connect(addr1).payAndSetUser(0, addr4.address, "1698676372", { value: amountToSend }); // already expired
    await expect(nftContract.connect(addr1).payAndSetUser(0, addr4.address, "1698676372"), { value: amountToSend }).to.be.revertedWith('Timestamp is in the past');
    expect(await nftContract.ownerOf(0)).to.equal(addr1.address);
    expect(await nftContract.userOf(0)).to.equal("0x0000000000000000000000000000000000000000");
  });

  it("should set user successfully, for future date", async () => {
    const timestamp = 33255651568;
    const now = Math.floor(Date.now() / 1000);
    console.log({ now })
    const difference = timestamp - now;
    console.log({ difference })
    const hours = new Date(difference).getHours();
    console.log({ hours })
    const amountToSend = ethers.parseEther("0.1");  // e.g., 0.1 ETH
    await nftContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    await nftContract.connect(addr1).payAndSetUser(0, addr4.address, timestamp, { value: amountToSend });
    expect(await nftContract.ownerOf(0)).to.equal(addr1.address);
    expect(await nftContract.userOf(0)).to.equal(addr4.address);

  });

  it("should transfer Ownership By Owner", async () => {
    await nftContract.setOwner(addr3.address);
    expect(await nftContract.owner()).to.equal(addr3.address);
  });


  // it("should fail when minting is disabled for collection", async () => {
  //   await contractDeployed.createCollection(
  //     "LINZ", "Ars Electronica", true, 1988146800000, 1000, "PLACE"
  //   );
  //   await contractDeployed.setMintingEnabled(1, false);

  //   try {
  //     await contractDeployed.createShiftNFT(1, "https://jsonplaceholder.typicode.com/todos/1", "0x61a5A64861c839f8F4D9fAA1F6b6F06052BA1C1B");
  //     assert.fail("The transaction should have failed but did not.");
  //   } catch (error) {
  //     console.error(error);
  //   }
  // });

  // it("should change tokenUri", async () => {
  //   await contractDeployed.createCollection(
  //     "LINZ", "Ars Electronica", true, 1988146800000, 1000, "PLACE"
  //   );
  //   await contractDeployed.createShiftNFT(1, "https://jsonplaceholder.typicode.com/todos/1", "0x61a5A64861c839f8F4D9fAA1F6b6F06052BA1C1B");
  //   await contractDeployed.setTokenURI(1, "https://bla");
  //   expect(await contractDeployed.uri(1)).to.equal("https://bla");

  // });

  // it("Should fail if collection closing date has expired", async function () {
  //   // Setting a past closing date for the collection
  //   await contractDeployed.createCollection(
  //     "LINZ", "Ars Electronica", true,
  //     946681200000, // 01 Jan 2000
  //     1000, "PLACE"
  //   );

  //   await contractDeployed.createShiftNFT(
  //     1,
  //     "ipfs://testURI",
  //     addr2.address
  //   );

  //   // Attempt to mint should fail because the collection's closing date has expired
  //   await expect(contractDeployed.connect(addr1).mint(addr1.address, 1, 1)).to.be.revertedWith("You're too late. Minting for this collection expired.");
  // });
});


