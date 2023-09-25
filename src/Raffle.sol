// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// Modifier order:
// Visibility
// Mutability
// Virtual
// Override
// Custom modifiers

// CEI: Checks, Effects, Interactions
//      checks
//      effects (changing state of our contract)
//      interactions (with other contracts)

pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title A raffle contract
/// @author Ethan Rouimi
/// @notice The contract creates a lottery
/// @dev For randomness it implements Chainlink VRFv2
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimeHasPassed();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__NotEnoughPlayers();
    error Raffle__UpkeepNotNeeded(
        uint256 actualBalance,
        uint numberOfPlayers,
        RaffleState raffleState
    );

    // Type declarations
    enum RaffleState {
        OPEN, // 0
        CLOSE // 1
    }

    // State variables
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMBER_OF_WORDS = 1;

    // Immutable variables
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    // @dev gas lane for Chainlink VRF
    bytes32 private immutable i_gasLane;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_entranceFee;
    // @dev duration of the lottery in seconds
    uint256 private immutable i_interval;

    address private s_lastWinner;
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;
    address payable[] private s_players;

    // Events
    event AddPlayerToRaffle(address indexed player);
    event WinnerOfRaffle(address player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 gasLane,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value >= i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit AddPlayerToRaffle(msg.sender);
    }

    /**
     * @dev This is the function that chainlinks nodes call to determine if
     * they need to call the desired function in this contract
     * The following should be true for thisfunction to return true:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is OPEN
     * 3. There are players participating in the raffle
     * 4. (Implicid) The subscription is paid with $LINK
     * @return upkeepNeeded boolean that determines if it's necesary to perfom
     * the automation
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* checkData */) {
        bool minimumTimePassed = (block.timestamp - s_lastTimeStamp) >=
            i_interval;

        // Check minimum time
        if (!minimumTimePassed) {
            return (false, "0x0");
        }

        // check if there's a minimum of 1 players
        if (s_players.length < 1) {
            return (false, "0x0");
        }

        // check Raffle State
        if (s_raffleState != RaffleState.OPEN) {
            return (false, "0x0");
        }

        // check if there's a balance in the contract
        if (address(this).balance > 0) {
            return (false, "0x0");
        }

        return (true, "0x0");
    }

    function performUpKeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                s_raffleState
            );
        }

        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CLOSE;

        // uint256 requestId =

        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUMBER_OF_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_lastWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerOfRaffle(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter Functions */

    function getEntranceFee() external view returns (uint) {
        return i_entranceFee;
    }

    function getPlayerByIndex(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRaffeState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
