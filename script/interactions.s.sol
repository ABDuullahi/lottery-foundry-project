// SPDX-License-Identifier: MIT

pragma solidity 0.8;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperconfig = new HelperConfig();
        (, , address vrfCoodinator, , , , ) = helperconfig
            .activeNetworkConfig();
        return createSubscription(vrfCoodinator);
    }

    function createSubscription(address vrfCoodinator) public returns (uint64) {
        console.log("Craeting subscription on ChainId:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoodinator).createSubscription();

        vm.stopBroadcast();
        console.log("Your sub Id is", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoodinator,
            ,
            uint64 subId,
            ,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoodinator, subId, link);
    }

    function fundSubscription(
        address vrfCoodinator,
        uint64 subId,
        address link
    ) public {
        console.log("Funding subscription:", subId);
        console.log("Using vrfcoodinator:", vrfCoodinator);
        console.log("On ChainID:", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoodinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoodinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );

            vm.stopBroadcast();
        }
    }

    function run() external {
        FundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfcoodinator,
        uint64 subId
    ) public {
        console.log("Adding consumer coontract:", raffle);
        console.log("Using vrfcoorninator:", vrfcoodinator);
        console.log("On chainID:", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfcoodinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoodinator, , uint64 subId, , ) = helperConfig
            .activeNetworkConfig();
        addConsumer(raffle, vrfCoodinator, subId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
