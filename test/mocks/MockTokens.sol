// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @dev A standard, fully ERC20-compliant token (returns bool from transfer)
/// — used to test the ordinary happy path.
contract MockERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/// @dev Mimics real mainnet USDT's actual (non-compliant) ABI: `transfer`
/// returns nothing at all, not even a bool. A naive `IERC20.transfer(...)`
/// call reverts against a token shaped like this — this is exactly the case
/// `SafeERC20` exists to handle, and exactly why the Vault uses it.
contract NonCompliantERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}

/// @dev A token whose transfer always reports failure — used to prove the
/// Vault actually reverts when a transfer fails, rather than silently
/// swallowing it.
contract FailingERC20 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }
}
