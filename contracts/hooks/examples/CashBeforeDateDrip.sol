// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {BaseHook} from "../../BaseHook.sol";

contract CashBeforeDateDrip is BaseHook {
    struct Payment {
        uint256 expirationDate; // Final date to cash
        uint256 lastCashed; // Last date when cashed
        uint256 dripAmount; // Amount available to cash each period
        uint256 dripPeriod; // Period after which cashing is allowed again
        address sender; // Sender of the payment
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Payment) public payments;

    error TooEarly();
    error Expired();
    error ExpirationDatePassed();
    error Disallowed();
    error OnlyToOwner();
    error ExceedsDripAmount();

    event PaymentCreated(uint256 indexed notaId, address indexed sender, uint256 cashBy, uint256 dripAmount, uint256 dripPeriod, string external_url, string imageURI);

    constructor(address registrar) BaseHook(registrar) {}

    function beforeWrite(
        address caller,
        NotaState calldata /*nota*/,
        uint256 notaId,
        bytes calldata writeData
    ) external override onlyRegistrar returns (bytes4, uint256) {
        (
            uint256 expirationDate,
            uint256 dripAmount,
            uint256 dripPeriod,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(writeData, (uint256, uint256, uint256, string, string));
        
        if (expirationDate <= block.timestamp) revert ExpirationDatePassed();
        
        payments[notaId] = Payment(expirationDate, 0, dripAmount, dripPeriod, caller, external_url, imageURI);

        emit PaymentCreated(notaId, caller, expirationDate, dripAmount, dripPeriod, external_url, imageURI);
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
        NotaState calldata nota,
        address to,
        uint256 amount,
        bytes calldata /*hookData*/
    ) external override onlyRegistrar returns (bytes4, uint256) {
        Payment storage payment = payments[nota.id];
        if (to == payment.sender){
            require(block.timestamp > payment.expirationDate, "NotExpired");
            return (this.beforeCash.selector, 0);
        }
        if (to != nota.owner) revert OnlyToOwner();
        if (block.timestamp > payment.expirationDate) revert Expired();
        if (block.timestamp < payment.lastCashed + payment.dripPeriod) revert TooEarly();
        if (amount > payment.dripAmount) revert ExceedsDripAmount();

        payment.lastCashed = block.timestamp;
        
        return (this.beforeCash.selector, 0);
    }

    function beforeTokenURI(
        address /*caller*/,
        NotaState calldata nota
    ) external view override returns (bytes4, string memory, string memory) {
        Payment memory payment = payments[nota.id];

        string memory dripPeriod = "";
        uint256 remainingTime = payment.dripPeriod;
        if (remainingTime >= 365 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 365 days, " year(s)");
            remainingTime %= 365 days;
        }
        if (remainingTime >= 30 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 30 days, " month(s)");
            remainingTime %= 30 days;
        }
        if (remainingTime >= 1 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 days, " day(s)");
            remainingTime %= 1 days;
        }
        if (remainingTime >= 1 hours) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 hours, " hour(s)");
            remainingTime %= 1 hours;
        }
        if (remainingTime >= 1 minutes) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 minutes, " minute(s)");
            remainingTime %= 1 minutes;
        }
        if (remainingTime >= 1 seconds) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 seconds, " second(s)");
        }

        return (
                this.beforeTokenURI.selector,
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Sender","value":"',
                        Strings.toHexString(payment.sender),
                        '"},{"trait_type":"Expiration Date","display_type":"date","value":"',
                        Strings.toString(payment.expirationDate),
                        '"},{"trait_type":"Last Cashed","display_type":"date","value":"',
                        Strings.toString(payment.lastCashed),
                        '"},{"trait_type":"Drip Amount","value":"',
                        Strings.toString(payment.dripAmount),
                        '"},{"trait_type":"Drip Period","value":"',
                        dripPeriod,
                        '"}'
                    )
                ),
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Cash Before Date Drip Nota #',
                        Strings.toHexString(nota.id),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"Allows the owner to claim the drip amount once every drip period. If the expiration date is exceeded the sender can take back the remaining tokens."'
                    )
                )
            );
    }

    function _appendTimeUnit(string memory current, uint256 time, uint256 unit, string memory unitName) private pure returns (string memory) {
        uint256 unitCount = time / unit;
        if (unitCount > 0) {
            return string(abi.encodePacked(current, bytes(current).length > 0 ? " " : "", Strings.toString(unitCount), unitName));
        }
        return current;
    }
}
