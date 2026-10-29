// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SavingsVaultFixed
/// @notice Security-hardened version of the Unit IV lab vault.
contract SavingsVaultFixed is ReentrancyGuard {
    address public immutable owner;
    uint256 public feeBps = 50; // 0.50%
    uint256 public collectedFees;
    mapping(address => uint256) public balances;

    uint256 public constant MAX_FEE_BPS = 1_000; // 10%

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event FeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeesClaimed(address indexed to, uint256 amount);

    error FeeTooHigh(uint256 requestedFeeBps, uint256 maxFeeBps);
    error ZeroAddress();
    error TransferFailed();

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdrawAll() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to withdraw");

        uint256 fee = (amount * feeBps) / 10_000;
        uint256 payout = amount - fee;

        // Checks-Effects-Interactions: update state before external call.
        balances[msg.sender] = 0;
        collectedFees += fee;
        emit Withdrawn(msg.sender, amount, fee);

        (bool ok, ) = payable(msg.sender).call{value: payout}("");
        if (!ok) revert TransferFailed();
    }

    function setFee(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) {
            revert FeeTooHigh(newFeeBps, MAX_FEE_BPS);
        }
        uint256 oldFeeBps = feeBps;
        feeBps = newFeeBps;
        emit FeeUpdated(oldFeeBps, newFeeBps);
    }

    function claimFees(address payable to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();

        uint256 amount = collectedFees;
        collectedFees = 0;

        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();

        emit FeesClaimed(to, amount);
    }
}
