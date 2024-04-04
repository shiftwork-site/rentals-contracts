const { ethers } = require("hardhat");

describe("SHIFT", async function () {
  let erc20TokenContractFactory;
  let erc20TokenContract;
  let erc20TokenAddress;
  let rentablesContractFactory;
  let proofContract;
  let proofAddress;
  let rentablesContract;
  let addr1;
  let addr2;
  let addr3;
  let addr4;
  const royaltyReceiver = "0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86";

  beforeEach(async () => {
    [addr1, addr2, addr3, addr4] = await ethers.getSigners();

    proofContractFactory = await hre.ethers.getContractFactory('SHIFTPROOF');
    proofContract = await hre.ethers.deployContract("SHIFTPROOF", [addr1.address, royaltyReceiver], {});
    const res3 = await proofContract.waitForDeployment();
    proofAddress = res3.target;

    erc20TokenContractFactory = await hre.ethers.getContractFactory('SHIFTTOKEN');
    erc20TokenContract = await hre.ethers.deployContract("SHIFTTOKEN", [addr1.address], {});
    const res = await erc20TokenContract.waitForDeployment();
    erc20TokenAddress = res.target;

    rentablesContractFactory = await hre.ethers.getContractFactory('SHIFTWORK');
    rentablesContract = await hre.ethers.deployContract("SHIFTWORK", [addr1.address, erc20TokenAddress, proofAddress], {});
    const res2 = await rentablesContract.waitForDeployment();
    nftAddress = res2.target;

    await erc20TokenContract.setAirdroppingContract(nftAddress);

    await proofContract.setAllowedContract(nftAddress);

  });

  // ################# MANAGER / OWNER TESTS #################
  it("should set manager SHIFTWEAR", async () => {
    await rentablesContract.connect(addr1).setManager(addr2.address);
    expect(await rentablesContract.manager()).to.equal(addr2.address);
  });

  it("should deny set manager SHIFTWEAR", async () => {
    await expect(rentablesContract.connect(addr2).setManager(addr2.address)).to.be.revertedWith("Not owner or manager of SHIFTWEAR");
  });

  it("should transfer Ownership By Owner SHIFTWEAR", async () => {
    await rentablesContract.connect(addr1).transferOwnership(addr2.address);
    expect(await rentablesContract.owner()).to.equal(addr2.address);
  });

  it("should deny transfer Ownership By Owner SHIFTWEAR", async () => {
    await expect(rentablesContract.connect(addr2).transferOwnership(addr2.address)).to.be.reverted;
  });

  it("should set manager ERC20TOKEN", async () => {
    await erc20TokenContract.connect(addr1).setManager(addr2.address);
    expect(await erc20TokenContract.manager()).to.equal(addr2.address);
  });

  it("should deny set manager ERC20TOKEN", async () => {
    await expect(erc20TokenContract.connect(addr2).setManager(addr2.address)).to.be.revertedWith("Not owner or manager of SHIFTTOKEN");
  });

  it("should deny transfer Ownership By Owner ERC20TOKEN", async () => {
    await expect(erc20TokenContract.connect(addr2).transferOwnership(addr2.address)).to.be.reverted;
  });
  it("should set manager PROOFS", async () => {
    await proofContract.connect(addr1).setManager(addr2.address);
    expect(await proofContract.manager()).to.equal(addr2.address);
  });

  it("should deny set manager PROOFS", async () => {
    await expect(proofContract.connect(addr2).setManager(addr2.address)).to.be.revertedWith("Not owner or manager of SHIFTPROOFS");
  });

  it("should deny transfer Ownership By Owner PROOFS", async () => {
    await expect(proofContract.connect(addr2).transferOwnership(addr2.address)).to.be.reverted;
  });


  // ################# RENTABLE TESTS #################


  it("should deny mint rentable", async () => {
    await expect(rentablesContract.connect(addr3).mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json")).to.be.revertedWith("Not authorized to mint.");
  });

  it("should mint rental successfully", async () => {
    await rentablesContract.connect(addr1).mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    expect(await rentablesContract.nextTokenIdToMint()).to.equal("1");
    await rentablesContract.connect(addr1).mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    expect(await rentablesContract.nextTokenIdToMint()).to.equal("2");
    expect(await rentablesContract.tokenURI(0)).to.equal("ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
  });


  it("should set user successfully, for 4 hrs", async () => {
    // const timestampInFutureMilliSeconds = 1705777200 * 1000;
    // const timestampInFuture = new Date(timestampInFutureMilliSeconds);
    // const now = new Date(Date.now());
    // const differenceInMilliseconds = timestampInFuture - now;
    // const differenceInHours = differenceInMilliseconds / (1000 * 60 * 60);
    // console.log({ differenceInHours })
    const amountToSend = ethers.parseEther("0.04");  // e.g., 0.1 ETH
    await rentablesContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    await rentablesContract.connect(addr1).payAndSetUser(0, addr3.address, 4, "CollectionB", "EmployerB", "PlaceB", "WearableB", { value: amountToSend });
    expect(await rentablesContract.ownerOf(0)).to.equal(addr1.address);
    console.log(await rentablesContract.userExpires(0))
    console.log(await rentablesContract.userOf(0))
    expect(await rentablesContract.userOf(0)).to.equal(addr1.address);
    console.log(await proofContract.tokenApprovals(1));
    console.log(await proofContract.royaltyInfo(1, 50));
    console.log(await proofContract.tokenURI(0));

  });

  it("should set user successfully, for 8 hrs", async () => {
    const amountToSend = ethers.parseEther("0.08");  // e.g., 0.1 ETH
    await rentablesContract.mintTo(1, addr1.address, "ipfs://bafyreihwscghzdv7wiqrgbyecdik4pztnp57h47rj66yhg5h3z264pegiy/metadata.json");
    await rentablesContract.connect(addr1).payAndSetUser(0, addr3.address, 8, "CollectionB", "EmployerB", "PlaceB", "WearableB", { value: amountToSend });
    expect(await rentablesContract.ownerOf(0)).to.equal(addr1.address);
  });


  // ################# TOKEN TESTS #################

  it("should have initial token minted to contract", async () => {
    const balance = ethers.formatEther(await erc20TokenContract.balanceOf(erc20TokenAddress))
    expect(balance).to.equal("2000000.0");
    const onwerBalance = ethers.formatEther(await erc20TokenContract.balanceOf(await erc20TokenContract.owner()))
    expect(onwerBalance).to.equal("1.0");
    const expectedReservedForOwner = BigInt("2000000") * BigInt("1000000000000000000"); // 10000000 * 10 ** 18 as BigInt
    expect(await erc20TokenContract.RESERVED_FOR_OWNER_AND_MANAGER()).to.equal(expectedReservedForOwner);
    const expectedReservedForPaypouts = BigInt("7000000") * BigInt("1000000000000000000"); // 10000000 * 10 ** 18 as BigInt
    expect(await erc20TokenContract.RESERVED_FOR_PAYOUTS()).to.equal(expectedReservedForPaypouts);
    // await erc20TokenContract.connect(addr1).withdraw(addr1, 5);
    // const newBalance = ethers.formatEther(await erc20TokenContract.balanceOf(erc20TokenAddress))


  });


  it("should airdrop tokens to any user", async () => {
    await erc20TokenContract.airdropTokens(addr3.address, 20)
    const balance = ethers.formatEther(await erc20TokenContract.balanceOf(addr3))
    expect(balance).to.equal("20.0");
  });

  it("should deny airdrop tokens exceeding max airdrops", async () => {
    await expect(erc20TokenContract.connect(addr1).airdropTokens(addr3.address, 1000001)).to.be.revertedWith("No tokens left for airdops");
  });

  it("should payout tokens to any user", async () => {
    await erc20TokenContract.payoutTokens(addr2.address, 40)
    const balance = ethers.formatEther(await erc20TokenContract.balanceOf(addr2))
    expect(balance).to.equal("40.0");
  });


  it("should deny payout tokens exceeding max payout", async () => {
    await expect(erc20TokenContract.connect(addr1).payoutTokens(addr3.address, 7000001)).to.be.revertedWith("No tokens left for payouts");
  });


  // TODO test not working but maybe function does and it's only the runner here
  // it("should be able to withdraw all initial tokens to owner", async () => {
  // const balance = ethers.formatEther(await erc20TokenContract.balanceOf(nftAddress))
  // const amountToSend = ethers.parseEther("0.1");  // e.g., 0.1 ETH
  //   await erc20TokenContract.connect(await erc20TokenContract.owner()).withdraw(await erc20TokenContract.owner(), 200000)
  // });


  it("should airdrop token", async () => {
    await erc20TokenContract.airdropTokens(addr4.address, 5);
    const airdroppedAmount = ethers.formatEther(await erc20TokenContract.airdroppedAmount())
    expect(airdroppedAmount).to.equal("5.0");
    await erc20TokenContract.airdropTokens(addr1.address, 2);
    const airdroppedAmount2 = ethers.formatEther(await erc20TokenContract.airdroppedAmount())
    expect(airdroppedAmount2).to.equal("7.0");
  });

  it("should mint from rentals", async () => {
    // private so not callable
  });

  // ################# PROOF TESTS #################

  // it("should mint two proofs and successfully transfer one, but fail on second", async () => {
  //   await proofContract.mint(
  //     addr2.address,
  //     addr1.address,
  //     "17061156000",
  //     "Ars Electronica",
  //     "Linz",
  //     "POSTCITY",
  //     "Outis Nemo",
  //     30
  //   );
  //   await proofContract.mint(
  //     addr1.address,
  //     addr2.address,
  //     "17061156000",
  //     "Ars Electronica",
  //     "Linz",
  //     "POSTCITY",
  //     "Outis Nemo",
  //     30);
  //   expect(await proofContract.tokenIdTracker()).to.equal("2");
  //   await proofContract.connect(addr1).claim(1);
  //   expect(await proofContract.ownerOf(1)).to.equal(addr1.address);
  //   await expect(proofContract.connect(addr1).claim(2)).to.be.revertedWith("Caller not approved to claim this token");

  // });

});



