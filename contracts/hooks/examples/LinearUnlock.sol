// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "../../BaseHook.sol";
import "openzeppelin/utils/Strings.sol";

// Allow 3rd party unauthorized addresses to claim tokens on behalf of owner? Mid-stream or only after full stream?
contract LinearUnlockHook is BaseHook {
    struct NotaData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    mapping(uint256 => NotaData) public notaData;

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        (uint256 startTime, uint256 endTime, uint256 totalAmount) = abi.decode(
            hookData,
            (uint256, uint256, uint256)
        );
        require(startTime < endTime, "Invalid time range");
        require(totalAmount > 0, "Total amount must be greater than zero");

        notaData[nota.id] = NotaData({
            startTime: startTime,
            endTime: endTime,
            totalAmount: totalAmount,
            claimedAmount: 0
        });

        return (this.beforeWrite.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata nota,
        address to,
        uint256 amount,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        require(to == nota.owner, "Not to owner");
        NotaData storage data = notaData[nota.id];

        uint256 blockTimestamp = block.timestamp;
        if (blockTimestamp < data.startTime) {
            revert("Unlocking has not started yet");
        }

        uint256 unlockedAmount;
        if (blockTimestamp >= data.endTime) {
            unlockedAmount = data.totalAmount;
        } else {
            unlockedAmount =
                (data.totalAmount * (blockTimestamp - data.startTime)) /
                (data.endTime - data.startTime);
        }

        uint256 claimableAmount = unlockedAmount - data.claimedAmount;
        require(amount <= claimableAmount, "Amount exceeds unlocked balance");

        data.claimedAmount += amount;

        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData storage data = notaData[nota.id];

        string memory attributes = string(
            abi.encodePacked(
                ',{"trait_type":"Start Time","value":"',
                Strings.toString(data.startTime),
                '"},{"trait_type":"End Time","value":"',
                Strings.toString(data.endTime),
                '"},{"trait_type":"Total Amount","value":"',
                Strings.toString(data.totalAmount),
                '"},{"trait_type":"Claimed Amount","value":"',
                Strings.toString(data.claimedAmount),
                '"}'
            )
        );

        string memory otherData = string(
            abi.encodePacked(
                ',"name":"Linear Unlock Nota #',
                Strings.toString(nota.id),
                '","description":"This Nota unlocks linearly from ',
                Strings.toString(data.startTime),
                ' to ',
                Strings.toString(data.endTime),
                '","external_url":"https://example.com/nota/',
                Strings.toString(nota.id),
                '"'
            )
        );

        return (this.beforeTokenURI.selector, attributes, otherData);
    }
}