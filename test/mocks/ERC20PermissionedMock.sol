// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20PermissionedBase, ERC20, IERC20} from "../../src/ERC20PermissionedBase.sol";

contract ERC20PermissionedMock is ERC20PermissionedBase {
    mapping(address => bool) internal _hasPermission;

    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken, address morpho, address bundler)
        ERC20PermissionedBase(name_, symbol_, underlyingToken, morpho, bundler)
    {}

    function hasPermission(address account) public view override returns (bool) {
        return _hasPermission[account] || super.hasPermission(account);
    }

    function setPermission(address account, bool permissioned) external {
        _hasPermission[account] = permissioned;
    }
}
