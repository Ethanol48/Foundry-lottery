// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract DeployRaffle is Script {
    /**
     * @notice Deploys Raffle Contract
     * @dev Deploys Raffle Contract using existing Config in HelperConfig, if the
     * subscription Id of the vrf contract is not set, it will create a new
     * subscription, fund it and add a consumer, the Raffle contract
     * @return Raffle, HelperConfig
     */
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            bytes32 gasLane,
            address vrfCoordinator,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken
        ) = helperConfig.activeNetwork();

        if (subscriptionId == 0) {
            // Creating Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator
                // deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                linkToken
                // deployerKey
            );
        }

        // (uint96 balanceOfSubscription, , , ) = VRFCoordinatorV2Mock(
        //     vrfCoordinator
        // ).getSubscription(subscriptionId);

        // if (balanceOfSubscription == 0) {
        //     FundSubscription fundSubscription = new FundSubscription();
        //     fundSubscription.fundSubscription(
        //         vrfCoordinator,
        //         subscriptionId,
        //         linkToken
        //         // deployerKey
        //     );
        // }

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

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId
        );

        return (raffle, helperConfig);
    }
}
