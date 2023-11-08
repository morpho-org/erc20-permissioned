// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {ERC20PermissionedMock} from "./mocks/ERC20PermissionedMock.sol";
import {ERC20PermissionedBase} from "../src/ERC20PermissionedBase.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "forge-std/Test.sol";

contract ERC20PermissionedBaseIntegrationTest is Test {
    address internal MORPHO = makeAddr("Morpho");
    address internal BUNDLER = makeAddr("Bundler");
    address internal RECEIVER = makeAddr("Receiver");

    ERC20PermissionedMock internal wrapper;
    ERC20Mock internal token;

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20PermissionedMock(token, MORPHO, BUNDLER);
    }

    function testDeployERC20PermissionedBase(string memory name, string memory symbol, address morpho, address bundler)
        public
    {
        ERC20Mock underlying = new ERC20Mock(name, symbol);
        ERC20PermissionedMock newWrapper = new ERC20PermissionedMock(IERC20Metadata(underlying), morpho, bundler);

        assertEq(newWrapper.name(), string.concat("Permissioned ", underlying.name(), " ", newWrapper.VERSION()));
        assertEq(newWrapper.symbol(), string.concat("p", underlying.symbol(), newWrapper.VERSION()));
        assertEq(address(newWrapper.underlying()), address(underlying));
        assertEq(newWrapper.MORPHO(), morpho);
        assertEq(newWrapper.BUNDLER(), bundler);
    }

    function testAddressZeroHasPermission() public {
        assertTrue(wrapper.hasPermission(address(0)));
    }

    function testMorphoHasPermission() public {
        assertTrue(wrapper.hasPermission(BUNDLER));
    }

    function testBundlerHasPermission() public {
        assertTrue(wrapper.hasPermission(BUNDLER));
    }

    function testHasPermission(address account) public {
        wrapper.setPermission(account, true);

        assertTrue(wrapper.hasPermission(account));
    }

    function testHasNoPermission(address account) public {
        assumeNotZeroAddress(account);
        vm.assume(account != MORPHO && account != BUNDLER);

        wrapper.setPermission(account, false);

        assertFalse(wrapper.hasPermission(account));
    }

    function depositFor(address account, uint256 value) public {
        _depositFor(account, value);

        assertEq(token.balanceOf(address(wrapper)), value);
        assertEq(wrapper.balanceOf(account), value);
    }

    function depositForNoPermission(address account, uint256 value) public {
        wrapper.setPermission(account, false);
        deal(address(token), account, value);

        vm.startPrank(account);
        token.approve(address(wrapper), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20PermissionedBase.NoPermission.selector, account));
        wrapper.depositFor(account, value);
    }

    function testTransfer(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        assumeNotZeroAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.transfer(to, value);

        assertEq(wrapper.balanceOf(from), 0);
        assertEq(wrapper.balanceOf(to), value);
    }

    function testTransferNoPermissionFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeCorrectAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(from, false);
        wrapper.setPermission(to, true);

        vm.prank(from);
        vm.expectRevert(abi.encodeWithSelector(ERC20PermissionedBase.NoPermission.selector, from));
        wrapper.transfer(to, value);
    }

    function testTransferNoPermissionTo(address to, uint256 value) public {
        _assumeCorrectAddress(to);

        _depositFor(RECEIVER, value);

        wrapper.setPermission(to, false);

        vm.prank(RECEIVER);
        vm.expectRevert(abi.encodeWithSelector(ERC20PermissionedBase.NoPermission.selector, to));
        wrapper.transfer(to, value);
    }

    function testTransferFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        assumeNotZeroAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.approve(address(this), value);

        wrapper.transferFrom(from, to, value);

        assertEq(wrapper.balanceOf(from), 0, "balanceOf(from)");
        assertEq(wrapper.balanceOf(to), value, "balanceOf(to)");
    }

    function testTransferFromNoPermissionFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeCorrectAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(from, false);
        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.approve(address(this), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20PermissionedBase.NoPermission.selector, from));
        wrapper.transferFrom(from, to, value);
    }

    function testTransferFromNoPermissionTo(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeCorrectAddress(from);
        _assumeCorrectAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(from, true);
        wrapper.setPermission(to, false);

        vm.prank(from);
        wrapper.approve(address(this), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20PermissionedBase.NoPermission.selector, to));
        wrapper.transferFrom(from, to, value);
    }

    function testWithdrawTo(address to, uint256 value) public {
        assumeNotZeroAddress(to);

        _depositFor(RECEIVER, value);

        wrapper.setPermission(to, true);

        vm.prank(RECEIVER);
        wrapper.withdrawTo(to, value);

        assertEq(wrapper.balanceOf(RECEIVER), 0);
        assertEq(token.balanceOf(to), value);
    }

    function _depositFor(address account, uint256 value) public {
        wrapper.setPermission(account, true);
        deal(address(token), account, value);

        vm.startPrank(account);
        token.approve(address(wrapper), value);
        wrapper.depositFor(account, value);
        vm.stopPrank();
    }

    function _assumeCorrectAddress(address account) internal view {
        vm.assume(account != BUNDLER);
        vm.assume(account != MORPHO);
        vm.assume(account != address(wrapper));
        assumeNotZeroAddress(account);
    }

    function _assumeNotEqual(address account1, address account2) internal pure {
        vm.assume(account1 != account2);
    }
}
