// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {CreateSubscription, FundSubscription} from "script/Interactions.s.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetwork;

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 gasLane;
        address vrfCoordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetwork = getSepoliaConfig();
        } else if (block.chainid == 80001) {
            activeNetwork = getMumbaiConfig();
        } else if (block.chainid == 31337) {
            activeNetwork = getAnvilConfig();
        }
    }

    function getMumbaiConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 1 ether,
                interval: 30,
                vrfCoordinator: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed,
                gasLane: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
                subscriptionId: 6044, // Update with subId
                callbackGasLimit: 700000, // 700,000 gas
                linkToken: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
            });
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // Update with subId
                callbackGasLimit: 700000, // 700,000 gas
                linkToken: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // We assume that if the vrfCoordinator value is set
        if (activeNetwork.vrfCoordinator != address(0)) {
            return activeNetwork;
        }

        // constructor parameters of vrf Mock
        uint96 baseFee = 0.25 ether; // 0.25 $LINK
        uint96 gasPriceLink = 1e9; // 1 gwei $LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinatorMock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0, // Update with subId
                callbackGasLimit: 700000, // 700,000 gas
                linkToken: address(linkToken)
            });
    }
}
