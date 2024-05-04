// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
// import "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;
  // 伪造一个发送合约的地址,这样与任何人一起工作时，都可以使用这个伪造的地址
  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE);
  }

  function testMinimumDollarIsFive() public view {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  // 这里fundMe合约的部署者是test合约，而我们正在调用test合约，所以msg.sender是我，因此两者不一致。要用address（this）表示此合约的地址
  function testOwnerIsMsgSender() public view {
    assertEq(fundMe.getOwner(), msg.sender);
    // assertEq(fundMe.i_owner(), address(this));
  }

  function testPricefeedVersionIsAccurate() public view {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
  }

  function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert(); // the next line should revert!
    fundMe.fund();
  }

  function testFundUpdatesFundedDataStructure() public {
    vm.prank(USER); // 告诉虚拟机下一笔交易由USER发送
    fundMe.fund{value: SEND_VALUE}();
    // uint256 amountFunded = fundMe.getAddressToAmountFunded(address(this));
    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
  }

  function testAddsFunderToArrayOfFunders() public {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }

  modifier funded() {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }
  function testOnlyownerCanWithdraw() public funded {
    vm.expectRevert();
    vm.prank(USER);
    fundMe.withdraw();
  }

  function testWithDrawWithASingleFunder() public funded {
    // 遵循arrange、act、assert的模式
    // Arrange， 安排测试，设置测试环境
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act，执行想要进行测试的操作
    uint256 gasStart = gasleft();
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    console.log(gasUsed);

    // Assert，断言测试
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
  }

  function testWithdrawFromMultipleFunders() public funded {
    // Arrange，solidity中地址是uint160类型，不能使用uint256
    uint160 numberOffunders = 10;
    uint160 startingFunderIndex = 1;
    for (uint160 i = startingFunderIndex; i < numberOffunders; i++) {
      hoax(address(i), SEND_VALUE);
      // vm.prank(address(i));
      // vm.deal(address(i), SEND_VALUE);
      // hoax会prank一个地址并赋予一些初始的ether
      fundMe.fund{value: SEND_VALUE}();
    }
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    // Assert
    assert(address(fundMe).balance == 0);
    assert(
      startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance
    );
  }
}
