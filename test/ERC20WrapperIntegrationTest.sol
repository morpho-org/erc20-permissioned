// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import {ERC20WrapperBase} from "../src/ERC20WrapperBase.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "forge-std/Test.sol";

contract ERC20WrapperIntegrationTest is Test {
    address internal MORPHO = makeAddr("Morpho");
    address internal BUNDLER = makeAddr("Bundler");

    ERC20WrapperBase internal wrapper;
    ERC20Mock internal token;

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20WrapperBase("wrapper", "WRP", token, MORPHO, BUNDLER);
    }

    function testDeployERC20WrapperBase(
        string memory name,
        string memory symbol,
        address underlying,
        address morpho,
        address bundler
    ) public {
        ERC20WrapperBase newWrapper = new ERC20WrapperBase(name, symbol, IERC20(underlying), morpho, bundler);

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
        vm.assume(account != MORPHO && account != BUNDLER);

        assertFalse(wrapper.hasPermission(account));
    }
}
