// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20WrapperBase} from "../src/ERC20WrapperBase.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "forge-std/Test.sol";

contract ERC20WrapperUnitTest is ERC20WrapperBase, Test {
    ERC20WrapperBase internal wrapper;
    ERC20Mock internal token;

    constructor() ERC20WrapperBase("wrapper", "WRP", token, makeAddr("Morpho"), makeAddr("Bundler")) {}

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20WrapperBase("wrapper", "WRP", token, MORPHO, BUNDLER);
    }

    function testAddressZeroHasPermission() public {
        assertTrue(hasPermission(address(0)));
    }

    function testMorphoHasPermission() public {
        assertTrue(hasPermission(BUNDLER));
    }

    function testBundlerHasPermission() public {
        assertTrue(hasPermission(BUNDLER));
    }

    function testHasPermissionRandomAddress(address account) public {
        vm.assume(account != MORPHO && account != BUNDLER);

        assertFalse(hasPermission(account));
    }

    function testUpdateFromNoPermission(address from, uint256 value) external {
        vm.assume(!hasPermission(from));

        vm.expectRevert(abi.encodeWithSelector(NoPermission.selector, from));
        _update(from, MORPHO, value);
    }

    function testUpdateToNoPermission(address to, uint256 value) external {
        vm.assume(!hasPermission(to));

        vm.expectRevert(abi.encodeWithSelector(NoPermission.selector, to));
        _update(MORPHO, to, value);
    }

    function testUpdateFromAndToPermissioned(uint256 value) external {
        deal(address(this), MORPHO, value);

        vm.expectEmit();
        emit Transfer(MORPHO, BUNDLER, value);
        _update(MORPHO, BUNDLER, value);

        assertEq(balanceOf(MORPHO), 0);
        assertEq(balanceOf(BUNDLER), value);
    }
}
