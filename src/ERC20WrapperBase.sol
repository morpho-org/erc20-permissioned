// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title ERC20WrapperBase
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice ERC20 wrapper contract to wrap/unwrap permissionless tokens and add a permissioning scheme.
/// @dev Inherit this contract and override the `hasPermission` and `_update` functions to change the permissioning
/// scheme.
contract ERC20WrapperBase is ERC20 {
    /* ERRORS */

    /// @dev Thrown when underlying token couldn't be wrapped.
    error ERC20InvalidUnderlying(address token);

    /// @notice Thrown when `account` has no permission.
    error NoPermission(address account);

    /* IMMUTABLES */

    /// @notice The address of the underlying token.
    IERC20 public immutable UNDERLYING;

    /// @notice The address of the Morpho contract.
    address public immutable MORPHO;

    /// @notice The number of decimals of the token.
    uint8 private _DECIMALS;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract.
    /// @param name_ The name of the token.
    /// @param symbol_ The symbol of the token.
    /// @param underlying The address of the underlying token.
    /// @param morpho The address of the Morpho contract. Can be the zero address.
    constructor(string memory name_, string memory symbol_, IERC20 underlying, address morpho) ERC20(name_, symbol_) {
        if (underlying == this) revert ERC20InvalidUnderlying(address(this));

        UNDERLYING = underlying;
        MORPHO = morpho;

        (bool success, uint8 underlyingDecimals) = _tryGetAssetDecimals(underlying);
        _DECIMALS = success ? underlyingDecimals : 18;
    }

    /* PUBLIC */

    /// @dev Allows a user to deposit underlying tokens and mints the corresponding number of wrapped tokens.
    function wrap(address account, uint256 value) public virtual returns (bool) {
        address sender = _msgSender();
        if (sender == address(this)) revert ERC20InvalidSender(address(this));
        if (account == address(this)) revert ERC20InvalidReceiver(account);

        SafeERC20.safeTransferFrom(UNDERLYING, sender, address(this), value);
        _mint(account, value);
        return true;
    }

    /// @dev Allows a user to burn a number of wrapped tokens and withdraws the corresponding number of underlying
    /// tokens.
    function unwrap(address onBehalf, address to, uint256 value) public virtual returns (bool) {
        if (onBehalf == address(this)) revert ERC20InvalidReceiver(onBehalf);

        _burn(onBehalf, value);
        SafeERC20.safeTransfer(UNDERLYING, to, value);
        return true;
    }

    /// @dev Returns true if `account` has no permission.
    /// @dev By default Morpho and Bundler have permission.
    /// @dev Override this function to change the permissioning scheme.
    function hasPermission(address account) public view virtual returns (bool) {
        return account == MORPHO;
    }

    /// @dev See {ERC20-decimals}.
    function decimals() public view virtual override returns (uint8) {
        return _DECIMALS;
    }

    /* INTERNAL */

    /// @dev See {ERC20Wrapper-_update}.
    /// @dev The sender is not checked. Override this function to check the sender if needed.
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from != address(0) && !hasPermission(from)) revert NoPermission(from);
        if (to != address(0) && !hasPermission(to)) revert NoPermission(to);

        super._update(from, to, value);
    }

    /// @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some
    /// way.
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) =
            address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }
}
