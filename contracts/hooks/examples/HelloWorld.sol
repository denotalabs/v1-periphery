// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/utils/Strings.sol";
import "../../BaseHook.sol";

contract HelloWorld is BaseHook {
    struct NotaData {
        string subject;
        string message;
    }

    mapping(uint256 => NotaData) public notaDatas;

    event MessageUpdated(uint256 indexed notaId, string subject, string message);

    constructor(address registrar) BaseHook(registrar) {}

    /**
     * @notice abi.encode(string name, string message);
     */
    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override returns (bytes4, uint256) {
        (string memory subject, string memory message) = abi.decode(hookData, (string, string));

        notaDatas[nota.id] = NotaData(subject, message);
        emit MessageUpdated(nota.id, subject, message);
        
        return (this.beforeWrite.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata nota,
        address to,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        require(to == nota.owner, "Only owner can cash out");
        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData memory notaData = notaDatas[nota.id];

        return (
            this.beforeTokenURI.selector,
            "",
            string(
                abi.encodePacked(
                    ',"name":"',
                    notaData.subject,
                    '","description":"',
                    notaData.message,
                    '"'
                )
            )
        );
    }
}