// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {BaseHook} from "../../BaseHook.sol";

contract SimpleTimelock is BaseHook {
    struct Timelock {
        uint256 releaseDate;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Timelock) public timelocks;

    event TimelockCreated(uint256 notaId, uint256 _releaseDate, string external_url, string imageURI);
    error OnlyOwnerOrApproved();

    constructor(
        address registrar
    ) BaseHook(registrar) {
    }

    function beforeWrite(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 notaId,
        bytes calldata hookData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        (uint256 _releaseDate, string memory external_url, string memory imageURI) = abi.decode(
            hookData,
            (uint256, string, string)
        );

        timelocks[notaId] = Timelock(_releaseDate, external_url, imageURI);

        emit TimelockCreated(notaId, _releaseDate, external_url, imageURI);
        return (this.beforeWrite.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external view override onlyRegistrar returns (bytes4, uint256) {
        revert("Only sending and cashing");
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata nota,
        address to,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        require(to == nota.owner, "Only cashable to owner");
        require(timelocks[nota.id].releaseDate < block.timestamp, "TIMELOCK");
        return (this.beforeCash.selector, 0);
    }

    function beforeApprove(
        address caller,
        NotaState calldata nota,
        address /*to*/
    ) external view override onlyRegistrar returns (bytes4, uint256) {
        require(caller == nota.owner, "Only owner can approve");
        return (this.beforeApprove.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        Timelock memory timelock = timelocks[nota.id];
        return (
            this.beforeTokenURI.selector,
            string(
                abi.encodePacked(
                    '{"trait_type":"Release Date","value":"',
                    timelock.releaseDate,
                    '"}'
                )
            ),
            string(
                abi.encodePacked(
                    ',"external_url":"',
                    timelock.external_url,
                    '","image":"',
                    timelock.imageURI,
                    '"'
                )
            )
        );
    }
}