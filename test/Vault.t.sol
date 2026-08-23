// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    address owner = makeAddr("owner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vault = new Vault(owner);
    }

    // ---------------------------------------------------------------
    // Construction
    // ---------------------------------------------------------------

    function test_ConstructorSetsOwner() public view {
        assertEq(vault.owner(), owner);
    }

    function test_ConstructorRevertsOnZeroAddress() public {
        vm.expectRevert(Vault.ZeroAddress.selector);
        new Vault(address(0));
    }

    // ---------------------------------------------------------------
    // Deposits
    // ---------------------------------------------------------------

    function test_AnyoneCanDeposit() public {
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        (bool ok,) = address(vault).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(vault.balance(), 1 ether);
    }

    function test_DepositEmitsEvent() public {
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, false, false, true);
        emit Vault.Deposited(address(this), 1 ether);
        (bool ok,) = address(vault).call{value: 1 ether}("");
        assertTrue(ok);
    }

    // ---------------------------------------------------------------
    // Access control — the core property under test
    // ---------------------------------------------------------------

    function test_OwnerCanWithdraw() public {
        vm.deal(address(vault), 1 ether);
        uint256 before = owner.balance;

        vm.prank(owner);
        vault.withdraw(0.4 ether);

        assertEq(owner.balance, before + 0.4 ether);
        assertEq(vault.balance(), 0.6 ether);
    }

    function test_OwnerCanWithdrawAll() public {
        vm.deal(address(vault), 1 ether);
        uint256 before = owner.balance;

        vm.prank(owner);
        vault.withdrawAll();

        assertEq(owner.balance, before + 1 ether);
        assertEq(vault.balance(), 0);
    }

    function test_NonOwnerCannotWithdraw() public {
        vm.deal(address(vault), 1 ether);
        vm.prank(attacker);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdraw(1 ether);
    }

    function test_NonOwnerCannotWithdrawAll() public {
        vm.deal(address(vault), 1 ether);
        vm.prank(attacker);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdrawAll();
    }

    function test_WithdrawMoreThanBalanceReverts() public {
        vm.deal(address(vault), 1 ether);
        vm.prank(owner);
        vm.expectRevert(Vault.InsufficientBalance.selector);
        vault.withdraw(2 ether);
    }

    function test_NoOwnershipTransferFunctionExists() public {
        // There is no transferOwnership selector on the contract at all —
        // any call to one reverts because it doesn't exist (no fallback).
        (bool ok,) = address(vault).call(abi.encodeWithSignature("transferOwnership(address)", attacker));
        assertFalse(ok);
        assertEq(vault.owner(), owner);
    }

    // ---------------------------------------------------------------
    // Reentrancy — owner is a malicious contract, should still be safe
    // ---------------------------------------------------------------

    function test_ReentrancyDuringWithdrawCannotDrainExtra() public {
        ReentrantOwner rOwner = new ReentrantOwner();
        Vault rVault = new Vault(address(rOwner));
        rOwner.setVault(rVault);

        vm.deal(address(rVault), 1 ether);

        vm.prank(address(rOwner));
        rVault.withdrawAll();

        // Reentrant calls during the single ETH transfer cannot pull out more
        // than the vault ever held, because balance is checked live each call.
        assertEq(address(rVault).balance, 0);
        assertEq(address(rOwner).balance, 1 ether);
    }

    // ---------------------------------------------------------------
    // Fuzz
    // ---------------------------------------------------------------

    function testFuzz_NonOwnerNeverWithdraws(address caller, uint256 amount) public {
        vm.assume(caller != owner);
        vm.deal(address(vault), 5 ether);
        amount = bound(amount, 0, 5 ether);

        vm.prank(caller);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdraw(amount);
    }

    function testFuzz_OwnerWithdrawNeverExceedsBalance(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 0, 1000 ether);
        vm.deal(address(vault), depositAmount);

        if (withdrawAmount > depositAmount) {
            vm.prank(owner);
            vm.expectRevert(Vault.InsufficientBalance.selector);
            vault.withdraw(withdrawAmount);
        } else {
            uint256 before = owner.balance;
            vm.prank(owner);
            vault.withdraw(withdrawAmount);
            assertEq(owner.balance, before + withdrawAmount);
        }
    }

    function testFuzz_DepositsAlwaysIncreaseBalance(uint96 amount) public {
        vm.deal(address(this), amount);
        uint256 before = vault.balance();
        (bool ok,) = address(vault).call{value: amount}("");
        assertTrue(ok);
        assertEq(vault.balance(), before + amount);
    }
}

/// @dev Helper contract used only to test that a malicious/reentrant owner
/// cannot extract more value than the vault holds.
contract ReentrantOwner {
    Vault public vault;
    uint256 public reentries;

    function setVault(Vault _vault) external {
        vault = _vault;
    }

    receive() external payable {
        if (reentries < 3 && address(vault).balance > 0) {
            reentries++;
            vault.withdrawAll();
        }
    }
}
