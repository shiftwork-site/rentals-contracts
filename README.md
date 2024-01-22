# Rental Contracts for SHIFT project

How to deploy on testnet Holesky (or any other EVP compatible blockchain.):

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js --network holesky
```

Verify contracts (enables readig/writing via etherscan):

```shell
npx hardhat verify --network holesky SHIFTWEAR_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS ROYALTY_RECEIVER_ADDRESS 100 ERC20_CONTRACT_ADDRESS PROOF_CONTRACT_ADDRESS
```

```shell
npx hardhat verify --network holesky ERC20_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS 
```

```shell
npx hardhat verify --network holesky PROOF_CONTRACT_ADDRESS INIITAL_OWNER_ADDRESS ROYALTY_RECEIVER_ADDRESS
```

