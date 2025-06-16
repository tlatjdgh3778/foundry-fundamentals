// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 0.1 ETH = 100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether;

    // 항상 setUp 함수가 실행된 후에 실행된다.
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFifty() public view {
        assertEq(fundMe.MINIMUM_USD(), 50e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender);
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
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    // fund 함수 호출 시 충분한 ETH가 없으면 revert 되는지 테스트
    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // 이 함수가 실행되면 revert 되어야 한다.

        fundMe.fund(); // 아무것도 보내지 않으면 revert 되어야 한다.
    }

    // fund 함수 호출 시 충분한 ETH가 있으면 펀드 데이터 구조가 업데이트되는지 테스트
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // 트랜잭션을 USER 로 보낸다.
        fundMe.fund{value: SEND_VALUE}(); // 10ETH

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
}
