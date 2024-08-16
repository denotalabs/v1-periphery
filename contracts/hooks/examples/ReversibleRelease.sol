// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {BaseHook} from "../../BaseHook.sol";

contract ReversibleRelease is BaseHook {
    struct NotaData {
        address payer;
        address inspector;
        string externalURI;
        string imageURI;
    }
    mapping(uint256 => NotaData) public notaDatas;

    event PaymentCreated(uint256 indexed notaId, address indexed payer, address indexed inspector, string externalURI, string imageURI);
    
    error OnlyOwner();
    error Disallowed();
    error AddressZero();
    error OnlyInspector();
    error OnlyOwnerOrApproved();

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address caller,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        (
            address inspector,
            string memory externalURI,
            string memory imageURI
        ) = abi.decode(hookData, (address, string, string));
        
        if (inspector == address(0)) revert AddressZero();

        notaDatas[nota.id] = NotaData(caller, inspector, externalURI, imageURI);

        emit PaymentCreated(nota.id, caller, inspector, externalURI, imageURI);
        return (this.beforeWrite.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        revert Disallowed();
    }

    function beforeCash(
        address caller,
        NotaState calldata nota,
        address to,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        require(caller == notaDatas[nota.id].inspector, "ONLY_INSPECTOR");
        require(to == nota.owner || to == notaDatas[nota.id].payer, "ONLY_TO_OWNER_OR_SENDER");
        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData memory hookData = notaDatas[nota.id];

        string memory attributes = string(
            abi.encodePacked(
                ',{"trait_type":"Inspector","value":"',
                Strings.toHexString(hookData.inspector),
                '"},{"trait_type":"Payer","value":"',
                Strings.toHexString(hookData.payer),
                '"}'
            )
        );

        string memory metadata = string(
            abi.encodePacked(
                ',"image":"', 
                hookData.imageURI, 
                '","name":"Reversible Release Nota #',
                Strings.toHexString(nota.id),
                '","external_url":"', 
                hookData.externalURI,
                '","description":"Allows the payer to choose the inspector who is then allowed to release the escrow to the owner OR back to the payer."'
            )
        );

        return (this.beforeTokenURI.selector, attributes, metadata);
    }
}