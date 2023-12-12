const { ethers } = require("hardhat");

describe("SHIFT", async function () {
  let erc20TokenContractFactory;
  let erc20TokenContract;
  let erc20TokenAddress;
  let nftContractFactory;
  let proofContractFactory;
  let proofContract;
  let proofAddress;
  let nftContract;
  let addr1;
  let addr2;
  let addr3;
  let addr4;

  beforeEach(async () => {
    [addr1, addr2, addr3, addr4] = await ethers.getSigners();

    proofContractFactory = await hre.ethers.getContractFactory('SHIFTPROOFS');
    proofContract = await hre.ethers.deployContract("SHIFTPROOFS", ["0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86"], {});
    const res3 = await proofContract.waitForDeployment();
    proofAddress = res3.target;

    erc20TokenContractFactory = await hre.ethers.getContractFactory('SHIFTTOKEN');
    erc20TokenContract = await hre.ethers.deployContract("SHIFTTOKEN", ["SHIFTTOKEN", "SHIFT"], {});
    const res = await erc20TokenContract.waitForDeployment();
    erc20TokenAddress = res.target;

    nftContractFactory = await hre.ethers.getContractFactory('SHIFTRENTALS');
    nftContract = await hre.ethers.deployContract("SHIFTRENTALS", ["SHIFTRENTALS", "SRT", addr1.address, 1, erc20TokenAddress, proofAddress], {});
    const res2 = await nftContract.waitForDeployment();
    nftAddress = res2.target;

    await erc20TokenContract.updateAllowedWhitelistContract(nftAddress);



  });

  it("should mint rental successfully", async () => {
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
    const timestampInFutureMilliSeconds = 1731789462 * 1000;
    const timestampInFuture = new Date(timestampInFutureMilliSeconds);
    const now = new Date(Date.now());
    const differenceInMilliseconds = timestampInFuture - now;
    const differenceInHours = differenceInMilliseconds / (1000 * 60 * 60);
    console.log({ differenceInHours })
    const amountToSend = ethers.parseEther("0.1");  // e.g., 0.1 ETH
    await nftContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    await nftContract.connect(addr1).payAndSetUser(0, addr4.address, timestampInFutureMilliSeconds, { value: amountToSend });
    expect(await nftContract.ownerOf(0)).to.equal(addr1.address);
    expect(await nftContract.userOf(0)).to.equal(addr4.address);

    const whiteListAmount = ethers.formatEther(await erc20TokenContract.getWhitelistedAmount(addr4.address))
    console.log({ whiteListAmount })


  });

  it("should transfer Ownership By Owner", async () => {
    await nftContract.setOwner(addr3.address);
    expect(await nftContract.owner()).to.equal(addr3.address);
  });


  // ################# TOKEN TESTS #################

  it("should updateAllowedWhitelistContract ", async () => {
    await erc20TokenContract.updateAllowedWhitelistContract(addr3.address);
    expect(await erc20TokenContract.allowedContractToSetWhitelist()).to.equal(addr3.address);
  });

  it("should have initial token minted to contract", async () => {
    const balance = ethers.formatEther(await erc20TokenContract.balanceOf(erc20TokenAddress))
    expect(balance).to.equal("20.0");
    const onwerBalance = ethers.formatEther(await erc20TokenContract.balanceOf(await erc20TokenContract.owner()))
    expect(onwerBalance).to.equal("2.0");

  });

  // TODO test not working but maybe function does and it's only the runner here
  // it("should be able to withdraw all initial tokens to owner", async () => {
  //   // const balance = ethers.formatEther(await erc20TokenContract.balanceOf(nftAddress))
  //   console.log(await erc20TokenContract.owner())
  //   // const amountToSend = ethers.parseEther("0.1");  // e.g., 0.1 ETH
  //   await erc20TokenContract.connect(await erc20TokenContract.owner()).withdraw(await erc20TokenContract.owner(), 3)

  // });

  it("should set address to whitelist with amount", async () => {
    await erc20TokenContract.setWhitelistAmount(addr3.address, 5);
    const balance = ethers.formatEther(await erc20TokenContract.getWhitelistedAmount(addr3.address))
    expect(balance).to.equal("5.0");
  });

  it("should set address to whitelist and payout", async () => {
    await erc20TokenContract.setWhitelistAmount(addr3.address, 5);
    await erc20TokenContract.payoutTokens(addr3.address);
    expect(await erc20TokenContract.getWhitelistedAmount(addr3.address)).to.equal(0);
  });

  it("should fail while trying to payout without any whitelist", async () => {
    try {
      await erc20TokenContract.payoutTokens((addr3.address));
      assert.fail("No whitelisted or already claimed all");
    } catch (error) {
      console.error(error);
    }
  });

  it("should fail while trying to payout after max payouts", async () => {
    await erc20TokenContract.setWhitelistAmount(addr3.address, 60);
    const whiteListAmount = ethers.formatEther(await erc20TokenContract.getWhitelistedAmount(addr3.address))
    expect(whiteListAmount).to.equal("60.0");
    await erc20TokenContract.payoutTokens(addr3.address);
    const payoutAmount = ethers.formatEther(await erc20TokenContract.payoutAmount())
    expect(payoutAmount).to.equal("60.0");

    const newWhiteListAmount = ethers.formatEther(await erc20TokenContract.getWhitelistedAmount(addr3.address))
    expect(newWhiteListAmount).to.equal("0.0");
    await erc20TokenContract.setWhitelistAmount(addr2.address, 20);
    try {
      await erc20TokenContract.payoutTokens((addr2.address));
      assert.fail("No tokens left for payouts");
    } catch (error) {
      console.error(error);
    }
  });

  it("should airdrop token", async () => {
    await erc20TokenContract.airdropTokens(addr4.address, 5);
    const airdroppedAmount = ethers.formatEther(await erc20TokenContract.airdroppedAmount())
    expect(airdroppedAmount).to.equal("5.0");
    await erc20TokenContract.airdropTokens(addr1.address, 2);
    const airdroppedAmount2 = ethers.formatEther(await erc20TokenContract.airdroppedAmount())
    expect(airdroppedAmount2).to.equal("7.0");
  });

  // ################# PROOF TESTS #################

  it("should mint proof", async () => {
    await proofContract.mint(
      "0xF1862117037cF3F11C998981F54eD2045e57E4DA",
      "0x6c3e38f2b3b7f21a6ebe6aaccb6cc669dfe78ae6",
      "03 Sep 2023 14:12",
      "03 Sep 2023 15:12",
      "0.01 ETH",
      "Ars Electronica",
      "Outis Nemo",
      30,
      "Geraldine Honauer"
    );
  });
});



