// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHIFTTOKEN is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 10000000 * 10 ** 18; // assuming 18 decimals
    uint256 public airdroppedAmount = 0;
    uint256 public withdrawnAmount = 0;
    uint256 public payoutAmount = 0;
    uint256 public constant RESERVED_FOR_AIRDROPS = (MAX_SUPPLY * 10) / 100;
    uint256 public constant RESERVED_FOR_PAYOUTS = (MAX_SUPPLY * 70) / 100;
    uint256 public constant RESERVED_FOR_OWNER_AND_MANAGER =
        (MAX_SUPPLY * 20) / 100;

    address public manager;
    address public airdroppingContract;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) ERC20("SHIFT TOKEN", "SHIFT") {
        manager = 0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86;
        _mint(address(this), RESERVED_FOR_OWNER_AND_MANAGER);
        _mint(owner(), 1 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
        _mint(manager, 1 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTTOKEN"
        );
        _;
    }
    
    function setAirdroppingContract(address _contract) external ownerOrMgr {
        airdroppingContract = _contract;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) external ownerOrMgr {
        uint256 formattedAmount = amount * 10 ** 18;
        require(
            formattedAmount <= balanceOf(address(this)),
            "Insufficient balance"
        );
        require(transfer(recipient, formattedAmount), "Token transfer failed");
        withdrawnAmount += amount;
        }

    function airdropTokens(address to, uint256 amount) external ownerOrMgr {
        uint256 formattedAmount = amount * 10 ** 18;

        require(
            formattedAmount < RESERVED_FOR_AIRDROPS - airdroppedAmount,
            "No tokens left for airdops"
        );
        _mint(to, formattedAmount);
        airdroppedAmount = airdroppedAmount + formattedAmount;
    }

    function payoutTokens(address to, uint256 amount) external {
        uint256 formattedAmount = amount * 10 ** 18;
        require(
            msg.sender == airdroppingContract || msg.sender == manager || msg.sender == owner(),
            "Not owner or manager or allowed contract to paypout token"
        );
        require(
            formattedAmount < RESERVED_FOR_PAYOUTS - payoutAmount,
            "No tokens left for payouts"
        );
        require(totalSupply() + formattedAmount <= MAX_SUPPLY, "Minting would exceed max supply");

        _mint(to, formattedAmount);
        payoutAmount += formattedAmount;
    }
}
