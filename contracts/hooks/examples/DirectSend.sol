// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {BaseHook} from "../../BaseHook.sol";

contract DirectSend is BaseHook {
    struct Payment {
        uint256 amount;
        string external_url;
        string imageURI;
    }
    mapping(uint256 => Payment) public payInfo;

    error EscrowUnsupported();
    error Disallowed();

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 instant,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        if (nota.escrowed != 0) revert EscrowUnsupported();

        (
            string memory external_url,
            string memory imageURI
        ) = abi.decode(hookData, (string, string));
        
        payInfo[nota.id] = Payment(instant, external_url, imageURI);
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
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external view override onlyRegistrar returns (bytes4, uint256) {
        revert Disallowed();
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        Payment memory payment = payInfo[nota.id];

        return (
            this.beforeTokenURI.selector,
            string(abi.encodePacked(
                ',{"trait_type":"Amount","value":"',
                Strings.toString(payment.amount),
                '"}'
            )),
            string(abi.encodePacked(
                ',"external_url":"',
                payment.external_url,
                '","name":"Direct Pay Nota #',
                Strings.toHexString(nota.id),
                '","image":"',
                payment.imageURI, 
                '","description":"Sends an image and a document along with a record of how much was paid."'
            ))
        );
    }
}
