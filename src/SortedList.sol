// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title SortedList
// @author @hexcowboy
// Sorted lists (values ordered greatest to least) with bytes4 keys
library SortedList {
    struct Node {
        bytes4 next; // the next node
        uint240 value; // value of the node
    }

    struct List {
        bytes4 first; // first element in the list
        uint240 length; // total amount of elements
        mapping(bytes4 => Node) nodes; // all nodes in list
    }

    // 0x0 means empty
    bytes4 private constant EMPTY = 0x0;

    // Inserts or overwrites a key with provided value
    // @param key: Four byte symbol (eg. "GOOG", "AAPL", "🤠")
    // @param value: Actual value that determines order (high to low)
    function upsert(
        List storage self,
        bytes4 key,
        uint240 value
    ) internal {
        require(value != 0, "value 0 is not permitted");
        require(key != EMPTY, "key 0x0 is not permitted");

        bytes4 previous;
        bytes4 cursor = self.first;

        while (self.nodes[cursor].value >= self.nodes[key].value + value) {
            previous = cursor;
            cursor = self.nodes[cursor].next;
        }

        if (key != cursor) {
            bytes4 oldNext = self.nodes[key].next;

            if (previous == EMPTY) {
                self.first = key;
                self.nodes[key].next = cursor;
            } else {
                self.nodes[key].next = self.nodes[previous].next;
                self.nodes[previous].next = key;
            }

            if (self.nodes[key].value > 0) {
                while (cursor != key) {
                    previous = cursor;
                    cursor = self.nodes[cursor].next;
                }
                if (self.nodes[previous].next != EMPTY) {
                    self.nodes[previous].next = oldNext;
                }
            }
        }

        self.nodes[key].value += value;

        unchecked {
            self.length++;
        }
    }

    // Get the position of a given key in the list
    function getPosition(List storage self, bytes4 key)
        internal
        view
        returns (uint256)
    {
        uint256 counter = 1;
        bytes4 current = self.first;
        while (current != key) {
            if (self.nodes[current].next == EMPTY) return 0;
            current = self.nodes[current].next;
            unchecked {
                counter++;
            }
        }
        return counter;
    }
}
