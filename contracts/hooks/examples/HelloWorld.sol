// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/utils/Strings.sol";
import "../../BaseHook.sol";

contract HelloWorldHook is BaseHook {
    struct HookData {
        string subject;
        string message;
        uint256 lastUpdated;
    }

    mapping(uint256 => HookData) public hookDatas;

    event MessageUpdated(uint256 indexed notaId, string newMessage);

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address /*caller*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override onlyRegistrar returns (uint256) {
        (string memory title, string memory message) = abi.decode(hookData, (string, string));

        hookDatas[notaId] = HookData(subject, message, block.timestamp);
        
        emit MessageUpdated(notaId, newSubject, message);
        return 0;
    }

    function beforeTransfer(
        address /*caller*/,
        uint256 notaId,
        uint256 /*escrowed*/,
        address /*owner*/,
        address /*from*/,
        address /*to*/,
        bytes calldata hookData
    ) external override onlyRegistrar returns (uint256) {
        if (hookData.length > 0) {
            (string memory newSubject, string memory newMessage) = abi.decode(hookData, (string, string));

            hookDatas[notaId].subject = newSubject;
            hookDatas[notaId].message = newMessage;
            hookDatas[notaId].lastUpdated = block.timestamp;

            emit MessageUpdated(notaId, newSubject, newMessage);
        }
        return 0;
    }

    function beforeTokenURI(uint256 notaId) external view override returns (string memory, string memory) {
        HookData memory hookData = hookDatas[notaId];

        return (
            string(
                abi.encodePacked(
                    ',{"trait_type":"Last Updated","value":"',
                    Strings.toString(hookData.lastUpdated),
                    '"}'
                )
            ),
            string(
                abi.encodePacked(
                    ',"name":"',
                    hookData.subject,
                    '","description":"',
                    hookData.message,
                    '"'
                )
            )
        );
    }
}