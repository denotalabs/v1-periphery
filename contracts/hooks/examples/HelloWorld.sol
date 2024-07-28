// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/utils/Strings.sol";
import "../../BaseHook.sol";

contract HelloWorld is BaseHook {
    struct HookData {
        string subject;
        string message;
    }

    mapping(uint256 => HookData) public hookDatas;

    event MessageUpdated(uint256 indexed notaId, string subject, string message);

    constructor(address registrar) BaseHook(registrar) {}

    /**
     * @notice abi.encode(string name, string description, string imageURI, string externalURI);
     */
    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override returns (bytes4, uint256) {
        (string memory subject, string memory message) = abi.decode(hookData, (string, string));

        hookDatas[nota.id] = HookData(subject, message);
        emit MessageUpdated(nota.id, subject, message);
        
        return (this.beforeWrite.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        HookData memory hookData = hookDatas[nota.id];

        return (
            this.beforeTokenURI.selector,
            "",
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