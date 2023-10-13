// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is Test {
    /*
     *   Events
     */
    event AddPlayerToRaffle(address indexed player);
    event WinnerOfRaffle(address player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint public constant STARTING_USER_BALANCE = 10 ether;

    address public PLAYER1 = makeAddr("Player1");
    address public PLAYER2 = makeAddr("Player2");
    address public PLAYER3 = makeAddr("Player3");
    address public PLAYER4 = makeAddr("Player4");

    address[] players = [PLAYER1, PLAYER2, PLAYER3, PLAYER4];

    uint256 entranceFee;
    uint256 interval;
    bytes32 gasLane;
    address vrfCoordinator;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            gasLane,
            vrfCoordinator,
            subscriptionId,
            callbackGasLimit,
            linkToken
        ) = helperConfig.activeNetwork();

        giveFundsToUsers();
    }

    /*
     *   Helper Functions
     */

    function giveFundsToUsers() public {
        for (uint256 index = 0; index < players.length; index++) {
            vm.deal(players[index], STARTING_USER_BALANCE);
        }
    }

    /*
     *   State of Contract
     */

    function testIfRaffleIsOpenWhenDeploying() public view {
        assert(raffle.getRaffeState() == Raffle.RaffleState.OPEN);
    }

    /*
     *   Enter Raffle Tests
     */

    function testRaffleRevertWhenYouUnderpay() public {
        // pretend to be a player
        vm.prank(players[0]);

        // simulate not sending funds
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testPlayerisRecordedWhenEnteringRaffle() public {
        // pretend to be a player
        vm.prank(players[0]);

        raffle.enterRaffle{value: entranceFee}();
        address recordedPlayer = raffle.getPlayerByIndex(0);
        assert(recordedPlayer == players[0]);
    }

    function testEventPlayerisRecordedWhenEnteringRaffle() public {
        // pretend to be a player
        vm.prank(players[0]);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit AddPlayerToRaffle(players[0]);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsPickingWinner() public {
        // pretend to be a player
        vm.prank(players[0]);
        raffle.enterRaffle{value: entranceFee}();

        // advance time to a point we can pick a winner
        vm.warp(block.timestamp + interval + 100);
        raffle.performUpKeep("0x0");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        // pretend to be other player
        vm.prank(players[1]);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*
     *   Check Perform Upkeep
     */

    function testCheckUpkeepReturnsFalseWhenBalanceIsEmpty() public {
        // Let pass the interval
        vm.warp(block.timestamp + interval + 100);

        // boolean representing if the contract needs to be called
        (bool isUpkeepNeeded, ) = raffle.checkUpkeep("");

        // isUpkeepNeeded should be false
        assert(!isUpkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseWhenTimeHasNotPassed() public view {
        // Pass less time that what is required
        // vm.warp(block.timestamp + interval + 100);

        // boolean representing if the contract needs to be called
        (bool isUpkeepNeeded, ) = raffle.checkUpkeep("");

        // isUpkeepNeeded should be false
        assert(!isUpkeepNeeded);
    }

    /*
     *   Test Perform Upkeep
     */

    function testPerformUpkeepWhenEnoughTimeHasPassed() public {

        // Add players to raffle
        for (uint256 i = 0; i < players.length; i++) {
            vm.prank(players[i]);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        // Let pass the interval
        vm.warp(block.timestamp + interval + 100);
        
        raffle.checkUpkeep("");

    }

    /*
     *   Test Constructor Values
     */

    function testEntraceFeeIsEqualToNetworkConfig() public view {
        assert(raffle.getEntranceFee() == entranceFee);
    }

    function testIntervalIsEqualToNetworkConfig() public view {
        assert(raffle.getInterval() == interval);
    }

    function testGasLanelIsEqualToNetworkConfig() public view {
        assert(raffle.getGasLane() == gasLane);
    }

    function testVrfCoordinatorlIsEqualToNetworkConfig() public view {
        assert(raffle.getVrfCoordinator() == vrfCoordinator);
    }

    function testCallbackGasLimitIsEqualToNetworkConfig() public view {
        assert(raffle.getCallbackGasLimit() == callbackGasLimit);
    }

    // subscriptionId,
    // callbackGasLimit
}
