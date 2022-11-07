// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@forge-std/Test.sol";
import "@forge-std/StdCheats.sol";

import "src/PredictionMarket.sol";

contract PredictionMarketTest is Test {
    PredictionMarket market;

    uint256 constant UINT_56_MAX_SIZE = 72057594037927935;

    function setUp() public {
        market = new PredictionMarket();
    }

    function testFuzzCreateCycle(
        uint256 _startingBlock,
        uint32 _blockLength,
        uint64 _betPrice
    ) public {
        vm.assume(_betPrice > 0);
        uint256 cycleId = market.createCycle(
            _startingBlock,
            _blockLength,
            _betPrice
        );
        (
            uint256 startingBlock,
            uint64 blockLength,
            uint64 betPrice,
            uint128 balance
        ) = market.getCycle(cycleId);
        assertEq(_startingBlock, startingBlock);
        assertEq(_blockLength, blockLength);
        assertEq(_betPrice, betPrice);
        assertEq(balance, 0);
    }

    function testCycleIdIsIncremented() public {
        for (uint256 i = 0; i < 10; i++) {
            uint256 cycleId = market.createCycle(0, 0, 100);
            assertEq(cycleId, i);
        }
    }

    function testPlaceBetWithoutEtherFails() public {
        uint256 cycleId = market.createCycle(0, 1, 100);
        vm.expectRevert("no ether provided");
        market.placeBet{value: 0}(cycleId, hex"1010");
    }

    function testUnevenNumberOfBetsPlaceFails() public {
        uint256 cycleId = market.createCycle(0, 1, 100);
        vm.expectRevert("uneven number of bets placed");
        market.placeBet{value: 101}(cycleId, hex"1010");
    }

    function testTooManyBetsPlacedFails() public {
        uint256 cycleId = market.createCycle(0, 1, 1);
        vm.expectRevert("you placed too many bets, try placing multiple");
        market.placeBet{value: UINT_56_MAX_SIZE + 1}(cycleId, hex"1010");
    }

    function testBettingAfterCycleEndsFails() public {
        uint256 cycleId = market.createCycle(0, 1, 100);
        vm.roll(2); // sets block number to 2
        vm.expectRevert("the cycle has already ended");
        market.placeBet{value: 100}(cycleId, hex"1010");
    }

    function testFuzzPlaceBet(
        uint32 blockLength,
        uint256 betAmount,
        bytes4 symbol
    ) public {
        vm.assume(betAmount > 0);
        vm.assume(betAmount < UINT_56_MAX_SIZE);
        vm.assume(blockLength > 0);
        vm.assume(symbol > 0);
        uint256 cycleId = market.createCycle(1, blockLength, 1);
        uint256 betId = market.placeBet{value: betAmount}(cycleId, symbol);
        PredictionMarket.Bet memory bet = market.getBet(betId);
        assertEq(bet.symbol, symbol);
        assertEq(bet.amount, betAmount);
        assertEq(market.betsToCycles(betId), cycleId);
    }

    uint256 constant ROUNDS = 10;

    function testPlacementIsCorrect() public {
        uint256 cycleId = market.createCycle(1, 1, 1);
        bytes4[] memory symbols = new bytes4[](ROUNDS);

        for (uint256 i = 1; i < ROUNDS; i++) {
            bytes4 symbol = bytes4(bytes32(i) << 240);
            symbols[i] = symbol;
            for (uint256 x = 0; x < i; x++) {
                market.placeBet{value: i}(cycleId, symbol);
            }
        }

        for (uint256 i = 1; i < ROUNDS; i++) {
            uint256 ranking = market.getSymbolRanking(cycleId, symbols[i]);
            assertEq(ranking, ROUNDS - i);
        }
    }

    mapping(bytes4 => uint256) voteTotals;

    function testFuzzPlacement(
        uint8 betCost,
        address[ROUNDS] memory senders,
        bytes4[ROUNDS] memory symbols,
        uint8[ROUNDS * ROUNDS] memory votes
    ) public {
        vm.assume(betCost > 0);
        for (uint256 i = 0; i < symbols.length; i++) {
            vm.assume(symbols[i] != 0x0);
        }

        uint256 cycleId = market.createCycle(1, betCost, 1);

        for (uint256 x = 0; x < symbols.length; x++) {
            vm.deal(senders[x], 1 ether);
            vm.startPrank(senders[x]);
            for (uint256 y = x * ROUNDS; y < (x + 1) * ROUNDS; y++) {
                if (votes[y] > 0) {
                    market.placeBet{
                        value: uint256(votes[y]) * uint256(betCost)
                    }(cycleId, symbols[x]);
                    voteTotals[symbols[x]] += votes[y];
                }
            }
            vm.stopPrank();
        }

        uint256 ignoredLen = 0;
        bytes4[] memory results = new bytes4[](symbols.length);

        for (uint256 i = 0; i < symbols.length; i++) {
            uint256 highestIndex = i;
            bytes4 highest;

            for (uint256 x = 0; x < symbols.length; x++) {
                if (voteTotals[symbols[x]] > voteTotals[highest]) {
                    highest = symbols[x];
                    highestIndex = x;
                }
            }

            symbols[highestIndex] = 0x0; // clear symbol

            bool skip = false;
            for (uint256 j = 0; j < results.length; j++) {
                if (highest == results[j]) {
                    // already indexed, skip
                    ignoredLen++;
                    skip = true;
                }
            }

            if (!skip) {
                results[i - ignoredLen] = highest;
            }
        }

        for (uint256 i = 0; i < results.length - ignoredLen; i++) {
            uint256 ranking = market.getSymbolRanking(cycleId, results[i]);
            assertEq(ranking, i + 1);
        }
    }

    function testClaimingBeforeCycleEndsFails() public {
        uint256 cycleId = market.createCycle(0, 10, 100);
        vm.roll(5);
        uint256 betId = market.placeBet{value: 100}(cycleId, hex"1010");
        vm.expectRevert("the cycle has not yet ended");
        market.claimFunds(betId);
    }

    function testClaimingTwiceFails() public {
        uint256 cycleId = market.createCycle(0, 10, 100);

        vm.deal(0x1111111111111111111111111111111111111111, 1 ether);
        vm.startPrank(0x1111111111111111111111111111111111111111);

        uint256 betId = market.placeBet{value: 100}(cycleId, hex"1010");
        vm.roll(11);
        market.claimFunds(betId);
        vm.expectRevert("the funds were already claimed");
        market.claimFunds(betId);

        vm.stopPrank();
    }

    function testOnlyPlacerCanClaim() public {
        uint256 cycleId = market.createCycle(0, 10, 100);

        vm.deal(0x1111111111111111111111111111111111111111, 1 ether);
        vm.startPrank(0x1111111111111111111111111111111111111111);
        uint256 betId = market.placeBet{value: 100}(cycleId, hex"1010");
        vm.stopPrank();

        vm.roll(11);

        vm.startPrank(0x2222222222222222222222222222222222222222);
        vm.expectRevert("you did not place this bet");
        market.claimFunds(betId);
        vm.stopPrank();
    }

    // this doesnt actually check to see if claim amounts are correct, it just
    // checks to make sure the contract doesn't run out of money if everyone
    // claims their bet
    function testFuzzClaiming(
        uint8 betCost,
        address[ROUNDS] memory placers,
        uint8[ROUNDS] memory votes
    ) public {
        betCost = uint8(bound(betCost, 1, 256));
        for (uint256 i = 0; i < ROUNDS; i++) {
            vm.assume(votes[i] != 0);
            vm.assume(placers[i] != 0x000000000000000000636F6e736F6c652e6c6f67);
            vm.assume(placers[i] != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
            vm.assume(placers[i] != 0x4e59b44847b379578588920cA78FbF26c0B4956C);
            vm.assume(placers[i] != 0xCe71065D4017F316EC606Fe4422e11eB2c47c246);
            vm.assume(placers[i] != address(this));
            StdCheatsSafe.assumeNoPrecompiles(placers[i]);
        }

        uint256 cycleId = market.createCycle(1, 1, betCost);
        uint256[] memory betIds = new uint256[](ROUNDS);

        // place bets
        for (uint256 i = 0; i < ROUNDS; i++) {
            vm.deal(placers[i], uint256(votes[i]) * uint256(betCost) + 1 ether);
            vm.startPrank(placers[i]);
            uint256 betId = market.placeBet{
                value: uint256(votes[i]) * uint256(betCost)
            }(cycleId, hex"1010");
            betIds[i] = betId;
            vm.stopPrank();
        }

        vm.roll(2);

        // claim bets
        for (uint256 i = 0; i < betIds.length; i++) {
            vm.startPrank(placers[i]);
            market.claimFunds(betIds[i]);
            vm.stopPrank();
        }

        assertEq(address(market).balance, 0);
    }
}
