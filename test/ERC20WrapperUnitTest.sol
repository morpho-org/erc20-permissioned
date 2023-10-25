// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20WrapperBase} from "../src/ERC20WrapperBase.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import "./helpers/BaseTest.sol";

contract ERC20WrapperUnitTest is ERC20WrapperBase, BaseTest {
    ERC20WrapperBase internal wrapper;
    ERC20Mock internal token;

    mapping(address => bool) internal _hasPermission;

    constructor() ERC20WrapperBase("wrapper", "WRP", token, makeAddr("Morpho")) {}

    function setUp() public {
        token = new ERC20Mock("token", "TKN");
        wrapper = new ERC20WrapperBase("wrapper", "WRP", token, MORPHO);
    }

    function testAddressZeroHasPermission() public {
        assertTrue(hasPermission(address(0)));
    }

    function testMorphoHasPermission() public {
        assertTrue(hasPermission(MORPHO));
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

    function testUpdateFromAndToPermission(address from, address to, uint256 value) external {
        _assumeNotEqual(from, to);
        _assumeNotZeroAddressNorWrapper(from);
        _assumeNotZeroAddressNorWrapper(to);
        deal(address(this), from, value);

        _setPermission(from, true);
        _setPermission(to, true);

        vm.expectEmit();
        emit Transfer(from, to, value);
        _update(from, to, value);

        assertEq(balanceOf(from), 0);
        assertEq(balanceOf(to), value);
    }

    function _assumeNotZeroAddressNorWrapper(address account) internal view {
        assumeNotZeroAddress(account);
        vm.assume(account != address(this));
    }

    function _setPermission(address account, bool permissioned) internal {
        _hasPermission[account] = permissioned;
    }

    function hasPermission(address account) public view override returns (bool) {
        return _hasPermission[account] || super.hasPermission(account);
    }
}
