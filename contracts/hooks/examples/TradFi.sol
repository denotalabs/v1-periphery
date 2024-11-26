// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/utils/Strings.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "../../BaseHook.sol";

contract ZKKYC {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[4] signals;
        uint256 merkleTreeDepth;
    }
    function verifyProof(
        uint256[2] memory _pA,
        uint256[2][2] memory _pB,
        uint256[2] memory _pC,
        uint256[4] memory _pubSignals,
        uint256 merkleTreeDepth
    ) internal view returns (bool) {
        return true;
    }
}

// Open 9-5 and not weekends. Has a settlement time set by owner. Can be reversed by owner. Transferring requires recipient to have kyc.
contract TradFi is BaseHook, Ownable, Pausable, ZKKYC {
    struct NotaData {
        uint256 settlementTime;
        string memo;
    }

    uint256 public settlementDelay = 86400;  // 1 day
    mapping(uint256 => NotaData) public notaDatas;
    mapping(address => bool) public whitelistedTokens;

    constructor(address registrar) BaseHook(registrar) {}

    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    function setWhitelistedToken(address token, bool whitelisted) public onlyOwner {
        whitelistedTokens[token] = whitelisted;
    }

    function beforeWrite(
        address /*caller*/,
        NotaState calldata nota,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external override onlyRegistrar whenNotPaused returns (bytes4, uint256) {
        require(isBusinessHours(), "Only business hours");
        require(whitelistedTokens[nota.currency], "Only whitelisted tokens");

        (Proof memory senderKYC, Proof memory recipientKYC, string memory memo) = abi.decode(hookData, (Proof, Proof, string));
        
        require(verifyProof(senderKYC.a, senderKYC.b, senderKYC.c, senderKYC.signals, senderKYC.merkleTreeDepth), "Sender KYC failed");
        require(verifyProof(recipientKYC.a, recipientKYC.b, recipientKYC.c, recipientKYC.signals, recipientKYC.merkleTreeDepth), "Recipient KYC failed");

        notaDatas[nota.id] = NotaData(block.timestamp + settlementDelay, memo);
        return (this.beforeWrite.selector, 0);
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata nota,
        address to,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar whenNotPaused returns (bytes4, uint256) {
        require(isBusinessHours(), "Only business hours");
        require(block.timestamp >= notaDatas[nota.id].settlementTime, "Settlement time not reached");
        require(to == nota.owner, "Only owner can cash out");

        return (this.beforeCash.selector, 0);
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata hookData
    ) external virtual override onlyRegistrar whenNotPaused returns (bytes4, uint256) {
        require(isBusinessHours(), "Only business hours");
        (Proof memory callerKYC) = abi.decode(hookData, (Proof));
        require(verifyProof(callerKYC.a, callerKYC.b, callerKYC.c, callerKYC.signals, callerKYC.merkleTreeDepth), "Caller KYC failed");

        return (this.beforeFund.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        NotaData memory notaData = notaDatas[nota.id];

        return (
            this.beforeTokenURI.selector,
            string(
                abi.encodePacked(
                    '{"trait_type":"Settlement Time","value":"',
                    Strings.toString(notaData.settlementTime),
                    '"}'
                )
            ),
            string(
                abi.encodePacked(
                    ',"description":"',
                    notaData.memo,

                    '"'
                )
            )
        );
    }

    function isBusinessHours() public view returns (bool) {
        uint256 day = (block.timestamp / 86400 + 4) % 7;
        uint256 hour = (block.timestamp / 3600) % 24;
        return day >= 1 && day <= 5 && hour >= 9 && hour < 17;
    }
}