// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    // 항상 setUp 함수가 실행된 후에 실행된다.
    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumDollarIsFifty() public view {
        assertEq(fundMe.MINIMUM_USD(), 50e18);
    }
}
