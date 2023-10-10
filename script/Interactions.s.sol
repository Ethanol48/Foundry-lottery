// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            ,
            // entrance
            // interval
            // gasLane
            address vrfCoordinator,
            uint64 subId, // callback
            ,
            address linkToken
        ) = helperConfig.activeNetwork();
        return createSubscription(vrfCoordinator /* , deployerKey */);
    }

    function createSubscription(
        address vrfCoordinator
    )
        public
        returns (
            // uint256 deployerKey
            uint64
        )
    {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast /* deployerKey */();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();

        (
            ,
            ,
            ,
            address vrfCoordinator,
            uint64 subId,
            ,
            address linkToken
        ) = helperConfig.activeNetwork();

        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subId,
        address link // uint256 deployerKey
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        (uint96 balance, , , ) = VRFCoordinatorV2Mock(vrfCoordinator)
            .getSubscription(subId);
        console.log("\nBalance of subscription before funding: ", balance);

        if (block.chainid == 31337) {
            vm.startBroadcast /* deployerKey */();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast /*deployerKey*/();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }

        (balance, , , ) = VRFCoordinatorV2Mock(vrfCoordinator).getSubscription(
            subId
        );
        console.log("Balance of subscription after funding: ", balance);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }

    function addConsumer(
        address _raffle,
        address _vrfCoordinator,
        uint64 _subId
    ) public {
        console.log("Adding Consumer: ", _raffle);
        console.log("Using Coordinator: ", _vrfCoordinator);
        console.log("To subscription: ", _subId);
        console.log("On chainId: ", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();

        (, , , address vrfCoordinator, uint64 subId, , ) = helperConfig
            .activeNetwork();

        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, _raffle);
    }
}
