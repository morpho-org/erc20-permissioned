// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import {ERC20WrapperMock} from "./mocks/ERC20WrapperMock.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "forge-std/Test.sol";

contract ERC20WrapperIntegrationTest is Test {
    address internal MORPHO = makeAddr("Morpho");
    address internal BUNDLER = makeAddr("Bundler");
    address internal RECEIVER = makeAddr("Receiver");

    ERC20WrapperMock internal wrapper;
    ERC20Mock internal token;

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20WrapperMock("wrapper", "WRP", token, MORPHO, BUNDLER);
    }

    function testDeployERC20WrapperBase(
        string memory name,
        string memory symbol,
        address underlying,
        address morpho,
        address bundler
    ) public {
        ERC20WrapperMock newWrapper = new ERC20WrapperMock(name, symbol, IERC20(underlying), morpho, bundler);

        assertEq(newWrapper.name(), name);
        assertEq(newWrapper.symbol(), symbol);
        assertEq(address(newWrapper.underlying()), underlying);
        assertEq(newWrapper.MORPHO(), morpho);
        assertEq(newWrapper.BUNDLER(), bundler);
    }

    function testAddressZeroHasPermission() public {
        assertTrue(wrapper.hasPermission(BUNDLER));
    }

    function testMorphoHasPermission() public {
        assertTrue(wrapper.hasPermission(BUNDLER));
    }

    function testBundlerHasPermission() public {
        assertTrue(wrapper.hasPermission(BUNDLER));
    }

    function testHasPermissionRandomAddress(address account) public {
        assumeNotZeroAddress(account);
        vm.assume(account != MORPHO && account != BUNDLER);

        assertFalse(wrapper.hasPermission(account));
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

    function testTransfer(address from, address to, uint256 value) public {
        assumeNotZeroAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.transfer(to, value);

        assertEq(wrapper.balanceOf(from), 0);
        assertEq(wrapper.balanceOf(to), value);
    }

    function testTransferFrom(address from, address to, uint256 value) public {
        assumeNotZeroAddress(from);
        assumeNotZeroAddress(to);

        _depositFor(from, value);

        wrapper.setPermission(to, true);

        vm.prank(from);
        wrapper.approve(address(this), value);

        wrapper.transferFrom(from, to, value);

        assertEq(wrapper.balanceOf(from), 0);
        assertEq(wrapper.balanceOf(to), value);
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
}
