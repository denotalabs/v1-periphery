// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import "../../BaseHook.sol";

contract Metadata is BaseHook {
    struct NotaData {
        string attributes;
        string image;
        string title;
        string name;
        string external_url;
        string description;
    }

    mapping(uint256 => NotaData) public notaData;

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 instant,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        if (nota.escrowed > 0) revert();
        if (instant > 0) revert();

        (  // Can be set directly?
            string memory attributes,
            string memory image,
            string memory title,
            string memory name,
            string memory external_url,
            string memory description
        ) = abi.decode(
            hookData,
            (string, string, string, string, string, string)
        );

        notaData[nota.id] = NotaData({
            attributes: attributes,
            image: image,
            title: title,
            name: name,
            external_url: external_url,
            description: description
        });

        return (this.beforeWrite.selector, 0);
    }

    function beforeTransfer(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        return (this.beforeTransfer.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        revert();
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        revert();
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData memory data = notaData[nota.id];

        string memory attributesJSON = string(
            abi.encodePacked(
                '{"trait_type":"attributes","value":"',
                data.attributes,
                '"}'
            )
        );

        string memory additionalJSON = string(
            abi.encodePacked(
                ',"image":"',
                data.image,
                '","name":"',
                data.name,
                '","external_url":"',
                data.external_url,
                '","description":"',
                data.description,
                '"'
            )
        );

        return (
            this.beforeTokenURI.selector,
            attributesJSON,
            additionalJSON
        );
    }
}