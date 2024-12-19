// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "denota-protocol/src/interfaces/IHooks.sol";

/**
 * @title BaseHook
 * @dev Abstract base contract for implementing Nota hooks
 * @notice Provides default implementations and structure for hook functionality
 */
abstract contract BaseHook is IHooks {
    /**
     * @dev Example hook data structures
     * @notice Uncomment and modify these structures for your specific hook needs:
     *
     * struct NotaDetails {
     *     bytes32 arbitraryData;     // Hook-specific data attached to Nota state
     *     address allowedClaimer;    // Example: Address allowed to claim
     *     uint256 unlockTime;        // Example: Time when claims are allowed  
     *     bytes32 merkleRoot;        // Example: Root for allowlist validation
     * }
     *
     * struct NotaMetadata {
     *     string attributes;         // JSON array of trait objects
     *     string keyValues;         // Additional JSON key-value pairs
     * }
     *
     * Usage:
     * mapping(uint256 id => NotaDetails) internal _notaDetails;
     * mapping(uint256 id => NotaMetadata) internal _notaMetadata;
     */

    /// @notice Address of the Nota registrar contract
    address public immutable REGISTRAR;

    /// @dev Custom errors
    error NotRegistrar();
    error InitParamsInvalid();
    
    /// @dev Ensures caller is the registrar contract
    modifier onlyRegistrar() {
        if (msg.sender != REGISTRAR) revert NotRegistrar();
        _;
    }

    constructor(address registrar) {
        if (registrar == address(0)) revert InitParamsInvalid();
        REGISTRAR = registrar;
    }

    /**
     * @notice Called when a new Nota is created
     * @dev Override to implement custom logic for Nota creation
     * @param caller msg.sender initiating the call
     * @param nota Current Nota state (id, currency, escrowed, owner, approved)
     * @param instant Amount sent directly to recipient
     * @param hookData Custom encoded data for hook logic
     * @return bytes4 Function selector
     * @return uint256 Fee amount (if any)
     */
    function beforeWrite(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*instant*/, 
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Implementation pattern:
        // 1. Decode hookData using abi.decode()
        // 2. Validate parameters
        // 3. Store nota-specific data
        // 4. Return selector and optional fee
        return (this.beforeWrite.selector, 0);
    }

    function beforeTransfer(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here (generally loads the notaDetails as a memory variable, unless it's updated, and uses it's properties to check for validity and update state)
        return (this.beforeTransfer.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here (generally loads the notaDetails as a memory variable, unless it's updated, and uses it's properties to check for validity and update state)
        return (this.beforeFund.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here (generally loads the notaDetails as a memory variable, unless it's updated, and uses it's properties to check for validity and update state)
        // require(to == nota.owner, "Only cashable to owner");  // Could be a good default..
        return (this.beforeCash.selector, 0);
    }

    function beforeApprove(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here (generally loads the notaDetails as a memory variable, unless it's updated, and uses it's properties to check for validity and update state)
        return (this.beforeApprove.selector, 0);
    }

    function beforeBurn(
        address /*caller*/,
        NotaState calldata /*nota*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4) {
        // Add hook logic here
        return this.beforeBurn.selector;  // Could default this to disallowed
    }

    function beforeUpdate(
        address /*caller*/,
        NotaState calldata /*nota*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here (generally loads the notaDetails and/or notaMetadata as a memory variable, unless it gets updated, and uses it's properties to check for validity and update state)
        return (this.beforeUpdate.selector, 0);
    }

    /**
     * @notice Generates token URI metadata
     * @dev Override to customize token metadata
     * @param caller Address requesting the URI
     * @param nota Current Nota state
     * @return bytes4 Function selector
     * @return string Attribute JSON array
     * @return string Additional metadata fields
     */
    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata /*nota*/
    ) external view virtual override returns (bytes4, string memory, string memory) {
        // Add hook logic here (generally loads the notaMetadata as a memory variable and uses it's properties to create an onchain JSON)
        // NotaDetails memory notaDetails = _notaDetails[nota.id];
        // NotaMetadata memory notaMetadata = _notaMetadata[nota.id];
        return (
                this.beforeTokenURI.selector,
                string(
                    abi.encodePacked(
                        /*
                        ',{"trait_type":"<ATTRIBUTE_1>","value":"',
                        notaMetadata.attribute1, (if the field exists)
                        // Repeat...
                        '"},{"trait_type":"<ATTRIBUTE_N>","value":"',
                        notaMetadata.attributeN, (if the field exists)
                        '"}'
                        */
                    )
                ), 
                string(
                    abi.encodePacked(
                        /*
                        ',"image":"', 
                        notaMetadata.image (if the field exists)
                        '","name":"',
                        notaMetadata.name (if the field exists)
                        '","external_url":"',
                        notaMetadata.external_url (if the field exists)
                        '","description":"',
                        notaMetadata.description (if the field exists)
                        '"'
                        */
                    )
                )
            );
    }

    function notaBytes(uint256 /*notaId*/) external virtual override view returns (bytes memory) {
        // Use this to read/write arbitrary data to the Nota state
        return ""; //abi.encode(_notaData[notaId]);
    }
}