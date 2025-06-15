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

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), address(this));
    }

    // What can we do to work with addresses outside our system ?
    // 1. Unit
    //     - Testing a specific part of our code
    // 2. Integration
    //     - Testing how our code works with other parts of our code
    // 3. Forked
    //     - Testing our code on a simulated real environment
    // 4. Staging
    //     - Testing our code in a real environment that is not prod

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log("version", version);
        assertEq(version, 4);
    }
}
