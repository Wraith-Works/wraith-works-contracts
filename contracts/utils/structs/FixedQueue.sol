// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

library FixedQueue {
    error NoRoom();
    error NoItems();

    struct UIntFixedQueue {
        uint256 maxLength;
        DoubleEndedQueue.Bytes32Deque queue;
    }

    function length(UIntFixedQueue storage queue) internal view returns (uint256) {
        return DoubleEndedQueue.length(queue.queue);
    }

    function push(UIntFixedQueue storage queue, uint256 data) internal returns (bool, uint256) {
        if (queue.maxLength == 0) revert NoRoom();

        bool dropped = false;
        uint256 _data = 0;

        if (DoubleEndedQueue.length(queue.queue) == queue.maxLength) {
            dropped = true;
            _data = uint256(DoubleEndedQueue.popFront(queue.queue));
        }

        DoubleEndedQueue.pushBack(queue.queue, bytes32(data));

        return (dropped, _data);
    }

    function pop(UIntFixedQueue storage queue) internal returns (uint256) {
        if (DoubleEndedQueue.length(queue.queue) == 0) revert NoItems();
        return uint256(DoubleEndedQueue.popFront(queue.queue));
    }

    function contains(UIntFixedQueue storage queue, uint256 data) internal view returns (bool, uint256) {
        uint256 queueLength = DoubleEndedQueue.length(queue.queue);
        for (uint256 i = 0; i < queueLength;) {
            if (data == uint256(DoubleEndedQueue.at(queue.queue, i))) {
                return (true, i);
            }
            unchecked {
                i++;
            }
        }
        return (false, 0);
    }
}
