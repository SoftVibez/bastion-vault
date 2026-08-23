// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title Bastion Vault
/// @notice A minimal, immutable, single-owner vault. It holds ETH and lets the
///         owner withdraw it. That is the entire feature set.
///
/// @dev Design notes (read this before trying to find a bug):
///      - `owner` is set once in the constructor and is `immutable` — there is no
///        transferOwnership/renounceOwnership function, so ownership itself cannot
///        be a target.
///      - No proxy, no upgradability, no admin backdoor, no pausing. What you read
///        here is permanently what runs.
///      - No external calls except the final ETH transfer to `owner`, and that
///        transfer always happens last (checks-effects-interactions), so there is
///        no state left to corrupt via reentrancy even in principle.
///      - No token support, no delegatecall, no arbitrary call function. The only
///        way ETH leaves this contract is `withdraw`/`withdrawAll` paying `owner`.
contract Vault {
    address public immutable owner;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    error NotOwner();
    error ZeroAddress();
    error InsufficientBalance();
    error TransferFailed();

    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroAddress();
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Accept ETH. This is the only way funds enter the vault.
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw a specific amount to `owner`.
    function withdraw(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) revert InsufficientBalance();
        emit Withdrawn(owner, amount);
        (bool ok,) = owner.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Withdraw the entire balance to `owner`.
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;
        emit Withdrawn(owner, amount);
        (bool ok,) = owner.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    /// @notice Current balance held by the vault.
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}
