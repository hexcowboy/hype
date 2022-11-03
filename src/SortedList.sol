// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title SortedList
// @author @hexcowboy
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

    // @param key: Four byte symbol (eg. "GOOG", "AAPL", "🤠")
    // @param value: Actual value that determines order (low to high)
    function upsert(
        List storage self,
        bytes4 key,
        uint240 value
    ) internal {
        require(value != 0, "value 0 is not permitted");
        require(key != EMPTY, "key 0x0 is not permitted");

        bytes4 previous;
        bytes4 current = self.first;

        while (self.nodes[current].value >= value) {
            previous = current;
            current = self.nodes[current].next;
        }

        self.nodes[key] = Node({next: self.nodes[previous].next, value: value});

        if (previous == EMPTY) {
            self.first = key;
        }

        unchecked {
            self.length++;
        }
    }
}
