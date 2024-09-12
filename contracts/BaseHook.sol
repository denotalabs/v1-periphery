// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "denota-protocol/src/interfaces/IHooks.sol";

abstract contract BaseHook is IHooks {
    address public immutable REGISTRAR;

    error NotRegistrar();
    error InitParamsInvalid();

    modifier onlyRegistrar() {
        if (msg.sender != REGISTRAR) revert NotRegistrar();
        _;
    }

    constructor(address registrar) {
        if (registrar == address(0)) revert InitParamsInvalid();
        REGISTRAR = registrar;
    }

    function beforeWrite(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here
        return (this.beforeWrite.selector, 0);
    }

    function beforeTransfer(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here
        return (this.beforeTransfer.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here
        return (this.beforeFund.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here
        return (this.beforeCash.selector, 0);
    }

    function beforeApprove(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/
    ) external virtual override onlyRegistrar returns (bytes4, uint256) {
        // Add hook logic here
        return (this.beforeApprove.selector, 0);
    }

    function beforeBurn(
        address /*caller*/,
        NotaState calldata /*nota*/
    ) external virtual override onlyRegistrar returns (bytes4) {
        // Add hook logic here
        return this.beforeBurn.selector;
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata /*nota*/
    ) external view virtual override returns (bytes4, string memory, string memory) {
        // Add hook logic here
        return (this.beforeTokenURI.selector, "", "");
    }
}