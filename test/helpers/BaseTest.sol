// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract BaseTest is Test {
    function _assumeNotEqual(address account1, address account2) internal pure {
        vm.assume(account1 != account2);
    }
}
