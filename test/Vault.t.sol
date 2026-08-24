// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import {MockERC20, NonCompliantERC20, FailingERC20} from "./mocks/MockTokens.sol";

contract VaultTest is Test {
    Vault vault;
    MockERC20 token;
    address owner = makeAddr("owner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        token = new MockERC20();
        vault = new Vault(owner, address(token));
    }

    // ---------------------------------------------------------------
    // Construction
    // ---------------------------------------------------------------

    function test_ConstructorSetsOwnerAndToken() public view {
        assertEq(vault.owner(), owner);
        assertEq(address(vault.token()), address(token));
    }

    function test_ConstructorRevertsOnZeroOwner() public {
        vm.expectRevert(Vault.ZeroAddress.selector);
        new Vault(address(0), address(token));
    }

    function test_ConstructorRevertsOnZeroToken() public {
        vm.expectRevert(Vault.ZeroAddress.selector);
        new Vault(owner, address(0));
    }

    // ---------------------------------------------------------------
    // Deposits — plain ERC20 transfers, no special function needed
    // ---------------------------------------------------------------

    function test_AnyoneCanDeposit() public {
        token.mint(attacker, 100e6);
        vm.prank(attacker);
        token.transfer(address(vault), 100e6);
        assertEq(vault.balance(), 100e6);
    }

    // ---------------------------------------------------------------
    // Access control — the core property under test
    // ---------------------------------------------------------------

    function test_OwnerCanWithdraw() public {
        token.mint(address(vault), 100e6);

        vm.prank(owner);
        vault.withdraw(40e6);

        assertEq(token.balanceOf(owner), 40e6);
        assertEq(vault.balance(), 60e6);
    }

    function test_OwnerCanWithdrawAll() public {
        token.mint(address(vault), 100e6);

        vm.prank(owner);
        vault.withdrawAll();

        assertEq(token.balanceOf(owner), 100e6);
        assertEq(vault.balance(), 0);
    }

    function test_NonOwnerCannotWithdraw() public {
        token.mint(address(vault), 100e6);
        vm.prank(attacker);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdraw(100e6);
    }

    function test_NonOwnerCannotWithdrawAll() public {
        token.mint(address(vault), 100e6);
        vm.prank(attacker);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdrawAll();
    }

    function test_WithdrawMoreThanBalanceReverts() public {
        token.mint(address(vault), 100e6);
        vm.prank(owner);
        vm.expectRevert(Vault.InsufficientBalance.selector);
        vault.withdraw(200e6);
    }

    function test_NoOwnershipTransferFunctionExists() public {
        (bool ok,) = address(vault).call(abi.encodeWithSignature("transferOwnership(address)", attacker));
        assertFalse(ok);
        assertEq(vault.owner(), owner);
    }

    // ---------------------------------------------------------------
    // Non-standard token handling — this is the whole reason SafeERC20
    // is used instead of a raw token.transfer() call.
    // ---------------------------------------------------------------

    function test_WithdrawWorksWithNonCompliantToken() public {
        // Mirrors real mainnet USDT's actual ABI: transfer() returns nothing.
        NonCompliantERC20 usdtLike = new NonCompliantERC20();
        Vault v = new Vault(owner, address(usdtLike));
        usdtLike.mint(address(v), 100e6);

        vm.prank(owner);
        v.withdrawAll();

        assertEq(usdtLike.balanceOf(owner), 100e6);
    }

    function test_WithdrawRevertsWhenTokenReportsFailure() public {
        FailingERC20 badToken = new FailingERC20();
        Vault v = new Vault(owner, address(badToken));
        badToken.mint(address(v), 100e6);

        vm.prank(owner);
        vm.expectRevert();
        v.withdraw(50e6);
    }

    // ---------------------------------------------------------------
    // Fuzz
    // ---------------------------------------------------------------

    function testFuzz_NonOwnerNeverWithdraws(address caller, uint256 amount) public {
        vm.assume(caller != owner);
        token.mint(address(vault), 5000e6);
        amount = bound(amount, 0, 5000e6);

        vm.prank(caller);
        vm.expectRevert(Vault.NotOwner.selector);
        vault.withdraw(amount);
    }

    function testFuzz_OwnerWithdrawNeverExceedsBalance(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 0, 1_000_000e6);
        token.mint(address(vault), depositAmount);

        if (withdrawAmount > depositAmount) {
            vm.prank(owner);
            vm.expectRevert(Vault.InsufficientBalance.selector);
            vault.withdraw(withdrawAmount);
        } else {
            vm.prank(owner);
            vault.withdraw(withdrawAmount);
            assertEq(token.balanceOf(owner), withdrawAmount);
        }
    }

    function testFuzz_DepositsAlwaysIncreaseBalance(uint96 amount) public {
        token.mint(attacker, amount);
        uint256 before = vault.balance();
        vm.prank(attacker);
        token.transfer(address(vault), amount);
        assertEq(vault.balance(), before + amount);
    }
}
