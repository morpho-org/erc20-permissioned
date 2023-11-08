// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Wrapper} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

/// @title ERC20PermissionedBase
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice ERC20Permissioned contract to wrap/unwrap permission-less tokens and add a permissioning scheme.
/// @dev Inherit this contract and override the `hasPermission` and `_update` functions to change the permissioning
/// scheme.
contract ERC20PermissionedBase is ERC20Wrapper, ERC20Permit {
    /* ERRORS */

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    /* CONSTANT */

    /// @notice The version of the contract.
    string constant public VERSION = "v1.0";

    /* IMMUTABLES */

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The address of the Bundler contract.
    address public immutable BUNDLER;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract.
    /// @param underlyingToken The address of the underlying token.
    /// @param morpho The address of the Morpho contract. Can be the zero address.
    /// @param bundler The address of the Bundler contract. Can be the zero address.
    constructor(IERC20Metadata underlyingToken, address morpho, address bundler)
        ERC20Wrapper(underlyingToken)
        ERC20Permit(string.concat("Permissioned ", underlyingToken.name(), " ", VERSION))
        ERC20(string.concat("Permissioned ", underlyingToken.name(), " ", VERSION), string.concat("p", underlyingToken.symbol(), VERSION))
    {
        MORPHO = morpho;
        BUNDLER = bundler;
    }

    /* PUBLIC */

    /// @dev Returns true if `account` has no permission.
    /// @dev By default Morpho and Bundler have permission.
    /// @dev Override this function to change the permissioning scheme.
    function hasPermission(address account) public view virtual returns (bool) {
        return account == address(0) || account == MORPHO || account == BUNDLER;
    }

    /* ERC20 */

    /// @dev See {ERC20-decimals}.
    function decimals() public view virtual override(ERC20, ERC20Wrapper) returns (uint8) {
        return ERC20Wrapper.decimals();
    }

    /* INTERNAL */

    /// @dev See {ERC20Wrapper-_update}.
    /// @dev The sender is not checked. Override this function to check the sender if needed.
    function _update(address from, address to, uint256 value) internal virtual override {
        if (!hasPermission(from)) revert NoPermission(from);
        if (!hasPermission(to)) revert NoPermission(to);

        super._update(from, to, value);
    }
}
