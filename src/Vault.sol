// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Bastion Wallet
/// @notice A minimal, immutable, single-owner USDT vault. It holds a fixed
///         ERC20 token (USDT) and lets the owner withdraw it. That is the
///         entire feature set.
///
/// @dev Design notes (read this before trying to find a bug):
///      - `owner` and `token` are set once in the constructor and are
///        `immutable` — there is no transferOwnership function and no way to
///        redirect the contract at a different token later.
///      - No proxy, no upgradability, no admin backdoor, no pausing.
///      - Deposits are plain ERC20 transfers of `token` to this contract's
///        address — there is deliberately no `deposit()` function to call.
///        ERC20 tokens can always be sent to any address without that
///        address's cooperation, so adding a special deposit function would
///        only add a second, redundant code path without adding any actual
///        protection.
///      - Withdrawals use OpenZeppelin's `SafeERC20`, not a raw
///        `token.transfer()` call. USDT's original Ethereum deployment
///        famously does not return a `bool` from `transfer`/`approve`,
///        which breaks a strict ERC20 interface call outright. `SafeERC20`
///        handles both compliant and non-compliant tokens correctly — this
///        is exactly the kind of low-level correctness detail worth using
///        an audited library for rather than re-deriving by hand.
///      - No arbitrary call function, no delegatecall, no support for any
///        token other than the one fixed at deployment.
contract Vault {
    using SafeERC20 for IERC20;

    address public immutable owner;
    IERC20 public immutable token;

    event Withdrawn(address indexed to, uint256 amount);

    error NotOwner();
    error ZeroAddress();
    error InsufficientBalance();

    constructor(address _owner, address _token) {
        if (_owner == address(0) || _token == address(0)) revert ZeroAddress();
        owner = _owner;
        token = IERC20(_token);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Withdraw a specific amount of `token` to `owner`.
    function withdraw(uint256 amount) external onlyOwner {
        if (amount > token.balanceOf(address(this))) revert InsufficientBalance();
        emit Withdrawn(owner, amount);
        token.safeTransfer(owner, amount);
    }

    /// @notice Withdraw the entire token balance to `owner`.
    function withdrawAll() external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        emit Withdrawn(owner, amount);
        token.safeTransfer(owner, amount);
    }

    /// @notice Current token balance held by the vault.
    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
