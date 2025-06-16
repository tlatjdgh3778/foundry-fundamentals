// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
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
        assertEq(fundMe.getOwner(), msg.sender);
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

    // 펀더 목록에 추가되는지 테스트
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // 트랜잭션을 USER 로 보낸다.
        fundMe.fund{value: SEND_VALUE}(); // 0.1 ETH

        address funder = fundMe.getFunder(0); // 펀더 목록의 첫 번째 주소
        assertEq(funder, USER); // 펀더 목록의 첫 번째 주소가 USER 와 같은지 확인
    }

    modifier funded() {
        vm.prank(USER); // 트랜잭션을 USER 로 보낸다.
        fundMe.fund{value: SEND_VALUE}(); // 0.1 ETH
        _;
    }

    // 소유자만 출금할 수 있는지 테스트
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // 이 함수가 실행되면 revert 되어야 한다.
        vm.prank(USER); // 트랜잭션을 USER 로 보낸다.
        fundMe.withdraw(); // 출금을 시도한다.
    }

    // 한 명의 펀더만 출금할 수 있는지 테스트
    function testWithdrawFromASingleFunder() public funded {
        // Arrange  : 준비 단계 (테스트에 필요한 모든 것을 설정)
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // 소유자의 잔액
        uint256 startingFundMeBalance = address(fundMe).balance; // 컨트랙트의 잔액

        // Act      : 실행 단계 (테스트하고자 하는 실제 동작을 수행)
        vm.prank(fundMe.getOwner()); // 트랜잭션을 소유자로 보낸다.
        fundMe.withdraw(); // 출금을 시도한다.

        // Assert   : 검증 단계 (결과가 예상대로인지 확인)
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // 소유자의 잔액
        uint256 endingFundMeBalance = address(fundMe).balance; // 컨트랙트의 잔액

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    // 여러 명의 펀더가 출금할 수 있는지 테스트
    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // 10명의 펀더
        uint160 startingFunderIndex = 1; // 2번째 펀더부터 시작
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address
            // => hoax
            hoax(address(i), SEND_VALUE); // 10명의 펀더에게 0.1 ETH 보낸다.
            fundMe.fund{value: SEND_VALUE}(); // 0.1 ETH
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner()); // 트랜잭션을 소유자로 보낸다.
        fundMe.withdraw(); // 출금을 시도한다.
        vm.stopPrank(); // 트랜잭션을 소유자로 보내는 것을 멈춘다.

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}
