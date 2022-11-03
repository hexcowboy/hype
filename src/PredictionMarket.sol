// SPDX-License-Identifier: MIT
// (c) hexcowboy 2022-current
pragma solidity >=0.8.0;

import "@prb/PRBMathSD59x18.sol";
import "./RedBlackTree.sol";
import "./OrderStatisticsTree.sol";
import "./SortedList.sol";

contract PredictionMarket {
    using PRBMathSD59x18 for int256;
    using SortedList for SortedList.List;

    uint256 constant UINT_56_MAX_SIZE = 72057594037927935;

    // tight bit packing in here
    struct Bet {
        // four-byte symbol of the bet (AAPL, GOOG, 🤠, etc)
        bytes4 symbol; // 32 bits
        // represents if the reward was claimed or not
        bool claimed; // 8 bits
        // amount of bets the player wants to place
        uint56 amount; // 56 bits
        // the address that placed the bet
        address placer; // 160 bits
        // indicates timeliness of bet placement
        uint256 placement;
    }

    // contains all information for a betting cycle
    struct Cycle {
        uint256 startingBlock; // the current cycle's starting block
        uint64 blockLength; // amoutn of blocks the cycle will run for
        uint64 betPrice; // the cost of one bet in wei
        uint128 balance; // the total balance of the cycle
        SortedList.List leaderboard;
    }

    Bet[] bets;
    Cycle[] cycles;
    mapping(uint256 => uint256) betsToCycles;

    constructor() {}

    // creates a cycle (anyone can create a cycle)
    // metadata like the name and description of the cycle should be off-chain
    function createCycle(
        uint256 startingBlock,
        uint32 blockLength,
        uint64 betPrice
    ) public returns (uint256 cycleId) {
        require(betPrice > 0, "bet price must be greater than 0");

        Cycle storage cycle = cycles.push();
        cycle.startingBlock = startingBlock;
        cycle.blockLength = blockLength;
        cycle.betPrice = betPrice;

        // TODO emit event

        return cycles.length - 1;
    }

    // places bets based on how much wei was sent
    function placeBet(uint256 cycleId, bytes4 symbol)
        public
        payable
        returns (uint256 betId)
    {
        Cycle storage cycle = cycles[cycleId];
        require(msg.value > 0, "no ether provided");
        require(
            msg.value % cycle.betPrice == 0,
            "uneven number of bets placed"
        );
        require(
            msg.value <= UINT_56_MAX_SIZE,
            "you placed too many bets, try placing multiple"
        );
        // TODO require block number is valid
        require(
            block.number > cycle.startingBlock + cycle.blockLength,
            "the cycle has already ended"
        );

        uint256 totalBets = msg.value / cycle.betPrice;

        Bet memory bet = Bet(
            symbol,
            false,
            uint56(totalBets),
            msg.sender,
            cycle.leaderboard.length + 1
        );

        // create bet
        uint256 betIndex = bets.length;
        bets.push(bet);

        // add to cycle
        cycle.balance += uint128(msg.value);
        uint240 newBetAmount = cycle.leaderboard.nodes[symbol].value +
            uint240(totalBets);
        cycle.leaderboard.upsert(symbol, newBetAmount);
        betsToCycles[betIndex] = cycleId;

        // TODO emit event

        return bets.length - 1;
    }

    // TODO batchPlaceBet

    // claims funds from a cycle that have ended
    function claimFunds(uint256 betId) public {
        Cycle storage cycle = cycles[betsToCycles[betId]];
        Bet storage bet = bets[betId];

        require(
            cycle.startingBlock + cycle.blockLength < block.number,
            "the cycle has not yet ended"
        );
        require(!bet.claimed, "the funds were already claimed");
        require(bet.placer == msg.sender, "you did not place this bet");

        uint256 timeliness = (bet.placement + bet.amount) /
            cycle.leaderboard.nodes[bet.symbol].value;

        // send money to player
        payable(msg.sender).transfer(
            cycle.betPrice *
                bet.amount *
                // timeliness (-2x^2+2)
                uint256(-2 * int256((timeliness**2) + 2)) *
                // symbol ranking (-2*sqrt(x)+2)
                uint256(
                    -2 *
                        int256(bet.placement / cycle.leaderboard.length)
                            .sqrt() +
                        2
                )
        );
    }

    // TODO batchClaimFunds
}
