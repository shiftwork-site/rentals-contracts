# Rental Contracts for SHIFT project

How to deploy on testnet Sepolia (or any other EVM compatible blockchain.):

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network sepolia
```

Verify contracts (enables readig/writing via etherscan):

```shell
npx hardhat verify --network sepolia SHIFTWEAR_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS ERC20_CONTRACT_ADDRESS PROOF_CONTRACT_ADDRESS
```

```shell
npx hardhat verify --network sepolia ERC20_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS 
```

```shell
npx hardhat verify --network sepolia PROOF_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS ROYALTY_RECEIVER_ADDRESS
```

