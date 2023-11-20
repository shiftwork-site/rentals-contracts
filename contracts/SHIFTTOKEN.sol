// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";

contract SHIFTTOKEN is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100 * 10 ** 18; // assuming 18 decimals
    uint256 public airdroppedAmount = 0;
    // uint256 public withdrawnAmount = 0;
    uint256 public payoutAmount = 0;

    uint256 public constant RESERVED_FOR_AIRDROPS = (INITIAL_SUPPLY * 10) / 100;
    uint256 public constant RESERVED_FOR_PAYOUTS = (INITIAL_SUPPLY * 70) / 100;
    uint256 public constant RESERVED_FOR_OWNER_AND_MANAGER =
        (INITIAL_SUPPLY * 20) / 100;

    mapping(address => uint256) private _whitelistedAmounts;

    address public allowedContractToSetWhitelist;

    address public manager;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
        _setupOwner(msg.sender);
        _mint(address(this), RESERVED_FOR_OWNER_AND_MANAGER);
        _mint(owner(), 2 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
        _mint(manager, 1 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager"
        );
        _;
    }

    modifier allowedToSetWhitelist() {
        require(
            msg.sender == allowedContractToSetWhitelist ||
                msg.sender == owner() ||
                msg.sender == manager,
            "Caller is not the allowed contract or owner or manager"
        );
        _;
    }

    function updateAllowedWhitelistContract(address _newAllowedContract) external {
        allowedContractToSetWhitelist = _newAllowedContract;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) public ownerOrMgr {
        require(
            amount * 10 ** 18 <= balanceOf(address(this)),
            "Insufficient balance"
        );
        recipient.transfer(amount * 10 ** 18);
        // withdrawnAmount = withdrawnAmount + amount;
    }

    function airdropTokens(address to, uint256 amount) public ownerOrMgr {
        require(
            amount < RESERVED_FOR_AIRDROPS - airdroppedAmount,
            "No tokens left for airdops"
        );
        _mint(to, amount * 10 ** 18);
        airdroppedAmount = airdroppedAmount + amount * 10 ** 18;
    }

    function payoutTokens(address to) public {
        require(
            _whitelistedAmounts[to] > 0,
            "No whitelisted or already claimed all"
        );
        uint256 amount = _whitelistedAmounts[to];
        require(
            amount < RESERVED_FOR_PAYOUTS - payoutAmount,
            "No tokens left for payouts"
        );
        _mint(to, amount);
        setWhitelistAmount(to, 0);
        payoutAmount = payoutAmount + amount;
    }

    function setWhitelistAmount(
        address account,
        uint256 amount
    ) public allowedToSetWhitelist {
        require(account != address(0), "Invalid address");
        _whitelistedAmounts[account] = amount * 10 ** 18;
    }

    function getWhitelistedAmount(
        address account
    ) public view returns (uint256) {
        return _whitelistedAmounts[account];
    }

    function _canSetOwner() internal virtual override returns (bool) {}
}
