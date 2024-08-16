// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {BaseHook} from "../../BaseHook.sol";

/**
 * Solves whether the client HAS the money (Solvency)
 * Solves not being able to expose rug-pulls (Transparency)
 * Solves the client forgetting to pay (Timeliness)
 * Solves not being able to get an advance on future work (Liquidity)
 */
contract ReversibleByBeforeDate is BaseHook {
    struct NotaData {
        address sender;
        address inspector;
        uint256 inspectionEnd;
        string externalURI;
        string imageURI;
    }
    mapping(uint256 => NotaData) public notaDatas;

    event PaymentCreated(uint256 indexed notaId, address indexed payer, address indexed inspector, uint256 inspectionEnd, string externalURI, string imageURI);

    error AddressZero();
    error Disallowed();
    error InspectionEndPassed();

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address caller,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        (
            address inspector,
            uint256 inspectionEnd,
            string memory externalURI,
            string memory imageURI
        ) = abi.decode(hookData, (address, uint256, string, string));
        
        if (inspector == address(0)) revert AddressZero();
        if (inspectionEnd <= block.timestamp) revert InspectionEndPassed();

        notaDatas[nota.id] = NotaData(caller, inspector, inspectionEnd, externalURI, imageURI);

        emit PaymentCreated(nota.id, caller, inspector, inspectionEnd, externalURI, imageURI);
        return (this.beforeWrite.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        // Should this be allowed?
        revert Disallowed();
    }

    function beforeCash(
        address caller,
        NotaState calldata nota,
        address to,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        NotaData memory notaData = notaDatas[nota.id];

        if (notaData.inspectionEnd > block.timestamp) {  // Current time is during inspection period
            require(caller == notaData.inspector, "OnlyByInspector");
            require(to == notaData.sender, "OnlyToSender");
        } else {
            require(to == nota.owner, "OnlyToOwner");
        }
        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData memory notaData = notaDatas[nota.id];

        return (this.beforeTokenURI.selector,
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Inspector","value":"',
                        Strings.toHexString(notaData.inspector),
                        '"},{"trait_type":"Payer","value":"',
                        Strings.toHexString(notaData.sender),
                        '"},{"trait_type":"Inspection End","display_type":"date","value":"',
                        Strings.toString(notaData.inspectionEnd),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        notaData.imageURI, 
                        '","name":"Reversible By Before Date Nota #',
                        Strings.toHexString(nota.id),
                        '","external_url":"', 
                        notaData.externalURI,
                        '","description":"Allows the payer to choose an inspector. The inspector can reverse the payment only during the inspection period. After the inspection period only the owner can receive the funds."'
                    )
                )
            );
    }
}
