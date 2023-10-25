// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC20, ERC20Wrapper, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

contract ERC20WrapperBase is ERC20Wrapper {
    /* ERRORS */

    error NotPermissioned(address account);

    /* IMMUTABLES */

    address public immutable MORPHO;
    address public immutable BUNDLER;

    /* CONSTRUCTOR */

    /// @dev `morpho` and `bundler` can be the zero address.
    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken, address morpho, address bundler)
        ERC20Wrapper(underlyingToken)
        ERC20(name_, symbol_)
    {
        MORPHO = morpho;
        BUNDLER = bundler;
    }

    /* PUBLIC */

    function hasPermission(address account) public view virtual returns (bool) {
        return account == MORPHO || account == BUNDLER;
    }

    /* INTERNAL */

    /// @dev See {ERC20Wrapper-_update}.
    /// @dev The sender is not checked.
    function _update(address from, address to, uint256 value) internal virtual override {
        if (!hasPermission(from)) revert NotPermissioned(from);
        if (!hasPermission(to)) revert NotPermissioned(to);

        super._update(from, to, value);
    }
}
