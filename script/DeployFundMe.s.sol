// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
  function run() external returns (FundMe) {
    //在broadcast之前的交易都不会在真实网络上进行
    HelperConfig helperConfig = new HelperConfig();
    address ethusdPriceFeed = helperConfig.activeNetworkConfig();

    vm.startBroadcast();
    FundMe fundMe = new FundMe(ethusdPriceFeed);
    vm.stopBroadcast();
    return fundMe;
  }
}
