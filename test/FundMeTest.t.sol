// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
// import "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  function setUp() external {
    fundMe = new FundMe();
  }

  function testMinimumDollarIsFive() public view {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  // 这里fundMe合约的部署者是test合约，而我们正在调用test合约，所以msg.sender是我，因此两者不一致。要用address（this）表示此合约的地址
  function testOwnerIsMsgSender() public view {
    // assertEq(fundMe.i_owner(), msg.sender);
    assertEq(fundMe.i_owner(), address(this));
  }
}
