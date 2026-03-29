// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {LockBox} from "src/LockBox.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployLockBox is Script {
    /* Deploy function */
    function run() external returns (LockBox, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        address activePriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        LockBox lockBox = new LockBox(activePriceFeed);
        vm.stopBroadcast();

        return (lockBox, helperConfig);
    }
}
