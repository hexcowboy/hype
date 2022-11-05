// SPDX-License-Identifier: MIT
// (c) hexcowboy 2022-current
pragma solidity >=0.8.16;

import "forge-std/Test.sol";
import "src/SortedList.sol";

contract SortedListTest is Test {
    using SortedList for SortedList.List;
    SortedList.List public list;

    function testInsertZeroValueFails() public {
        vm.expectRevert("value 0 is not permitted");
        list.upsert(0x00000001, 0);
    }

    function testInsertZeroKeyFails() public {
        vm.expectRevert("key 0x0 is not permitted");
        list.upsert(0x0, 1);
    }

    function testInsertAnyValueSucceeds(uint240 item) public {
        vm.assume(item > 0);
        list.upsert(0x00000001, item);
    }

    function testLengthIncreasesOnInsert() public {
        for (uint256 i = 1; i < 10; i++) {
            list.upsert(0x00000001, uint240(i));
            assertEq(i, list.length);
        }
    }

    function testFirstChangesCorrectlyOnInsertIncrease() public {
        for (uint256 i = 1; i < 10; i++) {
            bytes4 key = bytes4(bytes32(i) << 240);
            list.upsert(key, uint240(i));
            assertEq(key, list.first);
        }
    }

    function testFirstRemainsOnInsertDecrease() public {
        for (uint256 i = 10; i > 0; i--) {
            bytes4 key = bytes4(bytes32(i) << 240);
            list.upsert(key, uint240(i));
            assertEq(hex"000a", list.first); // 0x000a = 10
        }
    }
}
