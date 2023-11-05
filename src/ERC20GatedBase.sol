// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Wrapper} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

/// @title ERC20GatedBase
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice ERC20Gated contract to wrap/unwrap non gated tokens and add a permissioning scheme.
/// @dev Inherit this contract and override the `hasPermission` and `_update` functions to change the permissioning
/// scheme.
contract ERC20GatedBase is ERC20Wrapper, ERC20Permit {
    /* ERRORS */

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    /* IMMUTABLES */

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The address of the Bundler contract.
    address public immutable BUNDLER;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param underlyingToken The address of the underlying token.
    /// @param morpho The address of the Morpho contract. Can be the zero address.
    /// @param bundler The address of the Bundler contract. Can be the zero address.
    constructor(string memory name_, string memory symbol_, IERC20 underlyingToken, address morpho, address bundler)
        ERC20Wrapper(underlyingToken)
        ERC20Permit(name_)
        ERC20(name_, symbol_)
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
