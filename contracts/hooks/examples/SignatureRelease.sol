// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/utils/cryptography/ECDSA.sol";
import "../../BaseHook.sol";

// Set and require a signature from a specific address in order to cash out an amount from a nota.
// Concept could be built upon so each valid signature unlocks a tranch.
contract SignatureRelease is BaseHook {
    using ECDSA for bytes32;

    mapping(uint256 => address) public notaSigner;
    
    error InvalidSigner();
    error InvalidSignature();
    error NotToOwner();

    constructor(address registrar) BaseHook(registrar) {}

    /**
     * @notice abi.encode(address signer);
     */
    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        address signer = abi.decode(hookData, (address));
        if (signer == address(0)) revert InvalidSigner();
        
        notaSigner[nota.id] = signer;
        return (this.beforeWrite.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata nota,
        address to,
        uint256 amount,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        if (to != nota.owner) revert NotToOwner();
        
        bytes memory signature = hookData;
        
        bytes32 messageHash = keccak256(abi.encodePacked(nota.id, amount));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);
        
        if (recoveredSigner != notaSigner[nota.id]) revert InvalidSignature();
        
        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
        ) external view override returns (bytes4, string memory, string memory) {

        string memory attributesJSON = string(
            abi.encodePacked(
            '{"trait_type":"Required Signer","value":"',
            notaSigner[nota.id],
            '"}'
            )
        );

        string memory additionalJSON = string(
            abi.encodePacked(
            '"image":"", "name":"", "external_url":"", "description":""'
            )
        );

        return (
            this.beforeTokenURI.selector,
            attributesJSON,
            additionalJSON
        );
        }
}