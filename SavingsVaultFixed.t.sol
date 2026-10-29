// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SavingsVaultFixed} from "../contracts/SavingsVaultFixed.sol";

contract OwnerOriginHelper {
    function changeFee(SavingsVaultFixed vault, uint256 fee) external {
        vault.setFee(fee);
    }
}

contract SavingsVaultFixedTest is Test {
    SavingsVaultFixed vault;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner);
        vault = new SavingsVaultFixed();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_DepositCreditsSender() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function test_WithdrawAllPaysAmountMinusFee() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();
        vault.withdrawAll();
        vm.stopPrank();

        uint256 fee = (1 ether * vault.feeBps()) / 10_000;
        assertEq(alice.balance, 10 ether - fee);
        assertEq(vault.balances(alice), 0);
        assertEq(vault.collectedFees(), fee);
    }

    function test_RevertWhen_NonOwnerClaimsFees() public {
        vm.prank(alice);
        vm.expectRevert(bytes("not owner"));
        vault.claimFees(payable(alice));
    }

    function test_RevertWhen_DepositIsZero() public {
        vm.prank(alice);
        vm.expectRevert(bytes("zero deposit"));
        vault.deposit();
    }

    function test_OwnerClaimsExactFees() public {
        vm.startPrank(alice);
        vault.deposit{value: 1 ether}();
        vault.withdrawAll();
        vm.stopPrank();

        uint256 fees = vault.collectedFees();
        uint256 beforeBalance = bob.balance;
        vm.prank(owner);
        vault.claimFees(payable(bob));
        assertEq(bob.balance, beforeBalance + fees);
        assertEq(vault.collectedFees(), 0);
    }

    function test_OwnerCanSetFee() public {
        vm.prank(owner);
        vault.setFee(100);
        assertEq(vault.feeBps(), 100);
    }

    function test_RevertWhen_FeeAboveMaximum() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            SavingsVaultFixed.FeeTooHigh.selector,
            vault.MAX_FEE_BPS() + 1,
            vault.MAX_FEE_BPS()
        ));
        vault.setFee(vault.MAX_FEE_BPS() + 1);
    }

    function test_RevertWhen_ZeroAddressClaimsFees() public {
        vm.prank(owner);
        vm.expectRevert(SavingsVaultFixed.ZeroAddress.selector);
        vault.claimFees(payable(address(0)));
    }

    function test_RevertWhen_OriginOwnerCallsThroughHelper() public {
        OwnerOriginHelper helper = new OwnerOriginHelper();
        vm.prank(owner, owner);
        vm.expectRevert(bytes("not owner"));
        helper.changeFee(vault, 100);
    }

    function test_TwoDepositorsHaveIndependentBalances() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        vm.prank(bob);
        vault.deposit{value: 2 ether}();
        assertEq(vault.balances(alice), 1 ether);
        assertEq(vault.balances(bob), 2 ether);
    }

    function testFuzz_FeePlusPayoutEqualsDeposit(uint96 amount) public {
        amount = uint96(bound(amount, 1, 10 ether));
        vm.deal(alice, amount);

        vm.startPrank(alice);
        vault.deposit{value: amount}();
        vault.withdrawAll();
        vm.stopPrank();

        assertLe(vault.collectedFees(), amount);
        assertEq(alice.balance + vault.collectedFees(), amount);
    }
}
