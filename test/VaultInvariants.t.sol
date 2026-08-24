// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {MockERC20} from "./mocks/MockTokens.sol";

/// @notice Drives the vault with a mix of deposits, owner withdrawals, and
/// non-owner withdrawal attempts, tracking how much value ever left to
/// addresses other than the owner.
contract VaultHandler is Test {
    Vault public vault;
    MockERC20 public token;
    address public owner;
    address[] public attackers;

    uint256 public totalDeposited;
    uint256 public totalWithdrawnByOwner;
    uint256 public totalWithdrawnByAttackers;

    constructor(Vault _vault, MockERC20 _token, address _owner, address[] memory _attackers) {
        vault = _vault;
        token = _token;
        owner = _owner;
        attackers = _attackers;
    }

    function deposit(uint96 amount) external {
        token.mint(address(this), amount);
        token.transfer(address(vault), amount);
        totalDeposited += amount;
    }

    function ownerWithdraw(uint256 amount) external {
        amount = bound(amount, 0, vault.balance());
        uint256 before = token.balanceOf(owner);
        vm.prank(owner);
        try vault.withdraw(amount) {
            totalWithdrawnByOwner += (token.balanceOf(owner) - before);
        } catch {}
    }

    function ownerWithdrawAll() external {
        uint256 before = token.balanceOf(owner);
        vm.prank(owner);
        try vault.withdrawAll() {
            totalWithdrawnByOwner += (token.balanceOf(owner) - before);
        } catch {}
    }

    function attackerWithdraw(uint256 attackerSeed, uint256 amount) external {
        address attacker = attackers[bound(attackerSeed, 0, attackers.length - 1)];
        amount = bound(amount, 0, vault.balance() + 1_000e6);
        uint256 before = token.balanceOf(attacker);
        vm.prank(attacker);
        try vault.withdraw(amount) {
            // If this ever succeeds, the attacker just drained real funds.
            totalWithdrawnByAttackers += (token.balanceOf(attacker) - before);
        } catch {}
    }
}

contract VaultInvariantsTest is Test {
    Vault public vault;
    MockERC20 public token;
    VaultHandler public handler;
    address owner = makeAddr("owner");

    function setUp() public {
        token = new MockERC20();
        vault = new Vault(owner, address(token));

        address[] memory attackers = new address[](3);
        attackers[0] = makeAddr("attacker1");
        attackers[1] = makeAddr("attacker2");
        attackers[2] = makeAddr("attacker3");

        handler = new VaultHandler(vault, token, owner, attackers);
        targetContract(address(handler));
    }

    /// @dev The core promise of this whole project: no non-owner address ever
    /// extracts a single unit of the token, under any sequence of calls.
    function invariant_NoAttackerEverWithdraws() public view {
        assertEq(handler.totalWithdrawnByAttackers(), 0);
    }

    /// @dev Solvency: the vault can never pay out more than it ever received.
    function invariant_BalanceNeverExceedsDeposits() public view {
        assertLe(vault.balance() + handler.totalWithdrawnByOwner(), handler.totalDeposited());
    }
}
