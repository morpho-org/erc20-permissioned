// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ErrorsLib} from "../src/libraries/ErrorsLib.sol";

import {ERC20PermissionedBase} from "../src/ERC20PermissionedBase.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import "../lib/forge-std/src/Test.sol";

contract ERC20PermissionedBaseUnitTest is ERC20PermissionedBase, Test {
    ERC20Mock internal token;

    constructor() ERC20PermissionedBase("wrapper", "WRP", token, makeAddr("Morpho"), makeAddr("Bundler")) {}

    function setUp() public {
        token = new ERC20Mock();
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
        vm.assume(account != address(0) && account != MORPHO && account != BUNDLER);

        assertFalse(hasPermission(account));
    }

    function testUpdateFromNoPermission(address from, uint256 value) external {
        vm.assume(!hasPermission(from));

        vm.expectRevert(abi.encodeWithSelector(ErrorsLib.NoPermission.selector, from));
        _update(from, MORPHO, value);
    }

    function testUpdateToNoPermission(address to, uint256 value) external {
        vm.assume(!hasPermission(to));

        vm.expectRevert(abi.encodeWithSelector(ErrorsLib.NoPermission.selector, to));
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
