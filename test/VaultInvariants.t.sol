// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

/// @notice Drives the vault with a mix of deposits, owner withdrawals, and
/// non-owner withdrawal attempts, tracking how much value ever left to
/// addresses other than the owner.
contract VaultHandler is Test {
    Vault public vault;
    address public owner;
    address[] public attackers;

    uint256 public totalDeposited;
    uint256 public totalWithdrawnByOwner;
    uint256 public totalWithdrawnByAttackers;

    constructor(Vault _vault, address _owner, address[] memory _attackers) {
        vault = _vault;
        owner = _owner;
        attackers = _attackers;
    }

    function deposit(uint96 amount) external {
        vm.deal(address(this), amount);
        (bool ok,) = address(vault).call{value: amount}("");
        if (ok) totalDeposited += amount;
    }

    function ownerWithdraw(uint256 amount) external {
        amount = bound(amount, 0, address(vault).balance);
        uint256 before = owner.balance;
        vm.prank(owner);
        try vault.withdraw(amount) {
            totalWithdrawnByOwner += (owner.balance - before);
        } catch {}
    }

    function ownerWithdrawAll() external {
        uint256 before = owner.balance;
        vm.prank(owner);
        try vault.withdrawAll() {
            totalWithdrawnByOwner += (owner.balance - before);
        } catch {}
    }

    function attackerWithdraw(uint256 attackerSeed, uint256 amount) external {
        address attacker = attackers[bound(attackerSeed, 0, attackers.length - 1)];
        amount = bound(amount, 0, address(vault).balance + 1 ether);
        uint256 before = attacker.balance;
        vm.prank(attacker);
        try vault.withdraw(amount) {
            // If this ever succeeds, the attacker just drained real funds.
            totalWithdrawnByAttackers += (attacker.balance - before);
        } catch {}
    }
}

contract VaultInvariantsTest is Test {
    Vault public vault;
    VaultHandler public handler;
    address owner = makeAddr("owner");

    function setUp() public {
        vault = new Vault(owner);

        address[] memory attackers = new address[](3);
        attackers[0] = makeAddr("attacker1");
        attackers[1] = makeAddr("attacker2");
        attackers[2] = makeAddr("attacker3");

        handler = new VaultHandler(vault, owner, attackers);
        targetContract(address(handler));
    }

    /// @dev The core promise of this whole project: no non-owner address ever
    /// extracts a single wei from the vault, under any sequence of calls.
    function invariant_NoAttackerEverWithdraws() public view {
        assertEq(handler.totalWithdrawnByAttackers(), 0);
    }

    /// @dev Solvency: the vault can never owe out more than it ever received.
    function invariant_BalanceNeverExceedsDeposits() public view {
        assertLe(vault.balance() + handler.totalWithdrawnByOwner(), handler.totalDeposited());
    }
}
