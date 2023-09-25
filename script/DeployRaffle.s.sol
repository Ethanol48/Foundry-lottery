// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            bytes32 gasLane,
            address vrfCoordinator,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = helperConfig.activeNetwork();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            gasLane,
            vrfCoordinator,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return raffle;
    }
}
