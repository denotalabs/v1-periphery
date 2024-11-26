// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "../../BaseHook.sol";
import "openzeppelin/utils/Strings.sol";

// Allow 3rd party unauthorized addresses to claim tokens on behalf of owner? Mid-stream or only after full stream?
contract ReverseLinearUnlockHook is BaseHook {
    struct NotaData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
        address originalSender;
    }

    mapping(uint256 => NotaData) public notaData;

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address caller,
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
            claimedAmount: 0,
            originalSender: caller
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
        NotaData storage data = notaData[nota.id];

        uint256 blockTimestamp = block.timestamp;
        if (blockTimestamp < data.startTime) {
            revert("Unlocking has not started yet");
        }

        if (to == data.originalSender) {
            // Original sender can claim expired amount
            require(blockTimestamp > data.endTime, "Unlocking period has not ended yet");
            uint256 expiredAmount = data.totalAmount - data.claimedAmount;
            require(amount <= expiredAmount, "Amount exceeds expired balance");
            data.claimedAmount += amount;
        } else {
            // Owner can claim reduced amount linearly
            uint256 remainingTime = data.endTime - blockTimestamp;
            uint256 totalDuration = data.endTime - data.startTime;
            uint256 remainingAmount = (data.totalAmount * remainingTime) / totalDuration;

            uint256 claimableAmount = remainingAmount - data.claimedAmount;
            require(amount <= claimableAmount, "Amount exceeds unlocked balance");

            data.claimedAmount += amount;
        }

        return (this.beforeCash.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata nota,
        uint256 amount,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        NotaData storage data = notaData[nota.id];

        data.totalAmount += amount;
        data.endTime += (amount * (data.endTime - data.startTime)) / data.totalAmount;

        return (this.beforeFund.selector, 0);
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
                ',"name":"Reverse Linear Unlock Nota #',
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