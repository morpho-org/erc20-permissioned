// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import {ERC20WrapperBase} from "../src/ERC20WrapperBase.sol";
import {ERC20WrapperMock} from "./mocks/ERC20WrapperMock.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "./helpers/BaseTest.sol";

contract ERC20WrapperIntegrationTest is BaseTest {
    address internal MORPHO = makeAddr("Morpho");
    address internal RECEIVER = makeAddr("Receiver");
    address internal UNDERLYING = makeAddr("Underlying");

    ERC20WrapperMock internal wrapper;
    ERC20Mock internal token;

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20WrapperMock("wrapper", "WRP", token, MORPHO);
    }

    function testDeployERC20WrapperBase(string memory name, string memory symbol, address morpho) public {
        ERC20WrapperMock newWrapper = new ERC20WrapperMock(name, symbol, IERC20(UNDERLYING), morpho);

        assertEq(newWrapper.name(), name);
        assertEq(newWrapper.symbol(), symbol);
        assertEq(address(newWrapper.UNDERLYING()), UNDERLYING);
        assertEq(newWrapper.MORPHO(), morpho);
    }

    function testMorphoHasPermission() public {
        assertTrue(wrapper.hasPermission(MORPHO));
    }

    function testHasPermission(address account) public {
        wrapper.setPermission(account, true);

        assertTrue(wrapper.hasPermission(account));
    }

    function testHasNoPermission(address account) public {
        _assumeNotMorphoNorZeroAddressNorWrapper(account);

        wrapper.setPermission(account, false);

        assertFalse(wrapper.hasPermission(account));
    }

    function wrap(address account, uint256 value) public {
        _wrap(account, value);

        assertEq(token.balanceOf(address(wrapper)), value);
        assertEq(wrapper.balanceOf(account), value);
    }

    function wrapNoPermission(address account, uint256 value) public {
        wrapper.setPermission(account, false);
        deal(address(token), account, value);

        vm.startPrank(account);
        token.approve(address(wrapper), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20WrapperBase.NoPermission.selector, account));
        wrapper.wrap(account, value);
    }

    function testTransfer(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        assumeNotZeroAddress(from);
        assumeNotZeroAddress(to);

        _wrap(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.transfer(to, value);

        assertEq(wrapper.balanceOf(from), 0);
        assertEq(wrapper.balanceOf(to), value);
    }

    function testTransferNoPermissionFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeNotMorphoNorZeroAddressNorWrapper(from);
        assumeNotZeroAddress(to);

        _wrap(from, value);

        wrapper.setPermission(from, false);
        wrapper.setPermission(to, true);

        vm.prank(from);
        vm.expectRevert(abi.encodeWithSelector(ERC20WrapperBase.NoPermission.selector, from));
        wrapper.transfer(to, value);
    }

    function testTransferNoPermissionTo(address to, uint256 value) public {
        _assumeNotMorphoNorZeroAddressNorWrapper(to);

        _wrap(RECEIVER, value);

        wrapper.setPermission(to, false);

        vm.prank(RECEIVER);
        vm.expectRevert(abi.encodeWithSelector(ERC20WrapperBase.NoPermission.selector, to));
        wrapper.transfer(to, value);
    }

    function testTransferFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeNotZeroAddressNorWrapper(from);
        _assumeNotZeroAddressNorWrapper(to);

        _wrap(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.approve(address(this), value);

        wrapper.transferFrom(from, to, value);

        assertEq(wrapper.balanceOf(from), 0, "balanceOf(from)");
        assertEq(wrapper.balanceOf(to), value, "balanceOf(to)");
    }

    function testTransferFromNoPermissionFrom(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeNotMorphoNorZeroAddressNorWrapper(from);
        assumeNotZeroAddress(to);

        _wrap(from, value);

        wrapper.setPermission(from, false);
        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.approve(address(this), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20WrapperBase.NoPermission.selector, from));
        wrapper.transferFrom(from, to, value);
    }

    function testTransferFromNoPermissionTo(address from, address to, uint256 value) public {
        _assumeNotEqual(from, to);
        _assumeNotMorphoNorZeroAddressNorWrapper(from);
        _assumeNotMorphoNorZeroAddressNorWrapper(to);

        _wrap(from, value);

        wrapper.setPermission(from, true);
        wrapper.setPermission(to, false);

        vm.prank(from);
        wrapper.approve(address(this), value);

        vm.expectRevert(abi.encodeWithSelector(ERC20WrapperBase.NoPermission.selector, to));
        wrapper.transferFrom(from, to, value);
    }

    function testUnwrap(address to, uint256 value) public {
        assumeNotZeroAddress(to);

        _wrap(RECEIVER, value);

        wrapper.setPermission(to, true);

        vm.prank(RECEIVER);
        wrapper.unwrap(RECEIVER, to, value);

        assertEq(wrapper.balanceOf(RECEIVER), 0);
        assertEq(token.balanceOf(to), value);
    }

    function _wrap(address account, uint256 value) public {
        wrapper.setPermission(account, true);
        deal(address(token), account, value);

        vm.startPrank(account);
        token.approve(address(wrapper), value);
        wrapper.wrap(account, value);
        vm.stopPrank();
    }

    function _assumeNotZeroAddressNorWrapper(address account) internal view {
        assumeNotZeroAddress(account);
        vm.assume(account != address(wrapper));
    }

    function _assumeNotMorphoNorZeroAddressNorWrapper(address account) internal view {
        vm.assume(account != MORPHO);
        _assumeNotZeroAddressNorWrapper(account);
    }
}
