// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20WrapperBase, ERC20, IERC20} from "../../src/ERC20WrapperBase.sol";

contract ERC20WrapperMock is ERC20WrapperBase {
	mapping (address => bool) internal _hasPermission;

    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken, address morpho, address bundler)
        ERC20WrapperBase(name_, symbol_, underlyingToken, morpho, bundler)
    {}

	function hasPermission(address account) public view override returns (bool) {
		return _hasPermission[account] || super.hasPermission(account);
	}

	function setPermission(address account, bool permissioned) external {
		_hasPermission[account] = permissioned;
	}
}
