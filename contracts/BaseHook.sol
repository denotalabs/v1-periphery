// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
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
        uint256 /*notaId*/,
        address /*currency*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        uint256 /*instant*/,
        bytes calldata /*writeData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add hook logic here
        return 0;
    }

    function beforeTransfer(
        address /*caller*/,
        uint256 /*notaId*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        address /*from*/,
        address /*to*/,
        bytes calldata /*transferData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add hook logic here
        return 0;
    }

    function beforeFund(
        address /*caller*/,
        uint256 /*notaId*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*fundData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add hook logic here
        return 0;
    }

    function beforeCash(
        address /*caller*/,
        uint256 /*notaId*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*cashData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add hook logic here
        return 0;
    }

    function beforeApprove(
        address /*caller*/,
        uint256 /*notaId*/,
        uint256 /*escrowed*/,
        address /*owner*/,
        address /*to*/
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add hook logic here
        return 0;
    }

    function beforeBurn(
        address caller,
        uint256 notaId,
        uint256 escrowed,
        address owner
    ) external {
        // Add hook logic here
    }

    function beforeTokenURI(
        uint256 /*tokenId*/
    ) external view virtual override returns (string memory, string memory) {
        return ("", "");
    }
}

// abstract contract OperatorFeeModuleBase is INotaModule {
//     struct WTFCFees {
//         uint256 writeBPS;
//         uint256 transferBPS;
//         uint256 fundBPS;
//         uint256 cashBPS;
//     }
//     address public immutable REGISTRAR;
//     mapping(address => mapping(address => uint256)) public revenue; // rewardAddress => token => rewardAmount
//     mapping(address => WTFCFees) public dappOperatorFees;
//     uint256 internal constant BPS_MAX = 10_000;
//     string public _URI;

//     event ModuleBaseConstructed(address indexed registrar, uint256 timestamp);

//     error FeeTooHigh();
//     error NotRegistrar();
//     error InitParamsInvalid();

//     modifier onlyRegistrar() {
//         if (msg.sender != REGISTRAR) revert NotRegistrar();
//         _;
//     }

//     constructor(address registrar, WTFCFees memory _fees) {
//         if (registrar == address(0)) revert InitParamsInvalid();
//         if (BPS_MAX < _fees.writeBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.transferBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.fundBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.cashBPS) revert FeeTooHigh();

//         REGISTRAR = registrar;
//         dappOperatorFees[msg.sender] = _fees;

//         emit ModuleBaseConstructed(registrar, block.timestamp);
//     }

//     function setFees(WTFCFees memory _fees) public {
//         dappOperatorFees[msg.sender] = _fees;
//     }

//     function _takeReturnFee(
//         address currency,
//         uint256 amount,
//         address dappOperator,
//         uint8 _WTFC
//     ) internal returns (uint256 fee) {
//         if (_WTFC == 0) {
//             fee = dappOperatorFees[dappOperator].writeBPS;
//         } else if (_WTFC == 1) {
//             fee = dappOperatorFees[dappOperator].transferBPS;
//         } else if (_WTFC == 2) {
//             fee = dappOperatorFees[dappOperator].fundBPS;
//         } else if (_WTFC == 3) {
//             fee = dappOperatorFees[dappOperator].cashBPS;
//         } else {
//             revert("");
//         }
//         // TODO ensure this doesn't overflow
//         fee = (amount * fee) / BPS_MAX;
//         revenue[dappOperator][currency] += fee;
//     }

//     function beforeWrite(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 /*notaId*/,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata writeData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         address dappOperator = abi.decode(writeData, (address));
//         // Add hook logic here
//         return _takeReturnFee(currency, escrowed + instant, dappOperator, 0);
//     }

//     function beforeTransfer(
//         address /*caller*/,
//         address /*approved*/,
//         address /*owner*/,
//         address /*from*/,
//         address /*to*/,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata transferData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         address dappOperator = abi.decode(transferData, (address));
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, nota.escrowed, dappOperator, 1);
//     }

//     function beforeFund(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 amount,
//         uint256 instant,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata fundData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         address dappOperator = abi.decode(fundData, (address));
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, amount + instant, dappOperator, 2);
//     }

//     function beforeCash(
//         address /*caller*/,
//         address /*owner*/,
//         address /*to*/,
//         uint256 amount,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata cashData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         address dappOperator = abi.decode(cashData, (address));
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, amount, dappOperator, 3);
//     }

//     function beforeApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 notaId,
//         Nota calldata nota
//     ) external virtual override onlyRegistrar {
//         // Add hook logic here
//     }

//     function beforeTokenURI(
//         uint256 /*tokenId*/
//     ) external view virtual override returns (string memory, string memory) {
//         return ("", "");
//     }

//     function getFees(
//         address dappOperator
//     ) public view virtual returns (WTFCFees memory) {
//         return dappOperatorFees[dappOperator];
//     }

//     function withdrawFees(address token) public {
//         uint256 payoutAmount = revenue[msg.sender][token];
//         revenue[msg.sender][token] = 0;
//         if (payoutAmount > 0)
//             INotaRegistrar(REGISTRAR).hookWithdraw(
//                 token,
//                 payoutAmount,
//                 msg.sender
//             );
//     }
// }

// abstract contract OwnerFeeModuleBase is INotaModule, Ownable {
//     struct WTFCFees {
//         uint256 writeBPS;
//         uint256 transferBPS;
//         uint256 fundBPS;
//         uint256 cashBPS;
//     }
//     address public immutable REGISTRAR;
//     mapping(address => uint256) public revenue; // token => rewardAmount
//     WTFCFees public fees;
//     uint256 internal constant BPS_MAX = 10_000;
//     string public _URI;

//     event ModuleBaseConstructed(address indexed registrar, uint256 timestamp);

//     error FeeTooHigh();
//     error NotRegistrar();
//     error InitParamsInvalid();

//     modifier onlyRegistrar() {
//         if (msg.sender != REGISTRAR) revert NotRegistrar();
//         _;
//     }

//     constructor(address registrar, WTFCFees memory _fees) {
//         if (registrar == address(0)) revert InitParamsInvalid();
//         if (BPS_MAX < _fees.writeBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.transferBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.fundBPS) revert FeeTooHigh();
//         if (BPS_MAX < _fees.cashBPS) revert FeeTooHigh();

//         REGISTRAR = registrar;
//         fees = _fees;

//         emit ModuleBaseConstructed(registrar, block.timestamp);
//     }

//     function setFees(WTFCFees memory _fees) public onlyOwner {
//         fees = _fees;
//     }

//     function _takeReturnFee(
//         address currency,
//         uint256 amount,
//         uint8 _WTFC
//     ) internal returns (uint256 fee) {
//         if (_WTFC == 0) {
//             fee = fees.writeBPS;
//         } else if (_WTFC == 1) {
//             fee = fees.transferBPS;
//         } else if (_WTFC == 2) {
//             fee = fees.fundBPS;
//         } else if (_WTFC == 3) {
//             fee = fees.cashBPS;
//         } else {
//             revert("");
//         }
//         // TODO ensure this doesn't overflow
//         fee = (amount * fee) / BPS_MAX;
//         revenue[currency] += fee;
//     }

//     function beforeWrite(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 /*notaId*/,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata /*writeData*/
//     ) external virtual override onlyRegistrar returns (uint256) {
//         // Add hook logic here
//         return _takeReturnFee(currency, escrowed + instant, 0);
//     }

//     function beforeTransfer(
//         address /*caller*/,
//         address /*approved*/,
//         address /*owner*/,
//         address /*from*/,
//         address /*to*/,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata transferData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, nota.escrowed, 1);
//     }

//     function beforeFund(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 amount,
//         uint256 instant,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata fundData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, amount + instant, 2);
//     }

//     function beforeCash(
//         address /*caller*/,
//         address /*owner*/,
//         address /*to*/,
//         uint256 amount,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata cashData
//     ) external virtual override onlyRegistrar returns (uint256) {
//         // Add hook logic here
//         return _takeReturnFee(nota.currency, amount, 3);
//     }

//     function beforeApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 notaId,
//         Nota calldata nota
//     ) external virtual override onlyRegistrar {
//         // Add hook logic here
//     }

//     function beforeTokenURI(
//         uint256 /*tokenId*/
//     ) external view virtual override returns (string memory, string memory) {
//         // Add hook logic here
//         return ("", "");
//     }

//     function getFees(
//         address /*dappOperator*/
//     ) public view virtual returns (WTFCFees memory) {
//         return fees;
//     }

//     function withdrawFees(address token) public onlyOwner {
//         uint256 payoutAmount = revenue[token];
//         revenue[token] = 0;
//         if (payoutAmount > 0)
//             INotaRegistrar(REGISTRAR).hookWithdraw(
//                 token,
//                 payoutAmount,
//                 owner()
//             );
//     }
// }
