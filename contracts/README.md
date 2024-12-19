# Hook Development Guide

This guide aims to inspire and educate hook developers by providing ideas and examples of key hook primitives. These primitives include access control mechanisms, time-based conditions, signature-based authorizations, and more. The examples are drawn from various hook implementations to illustrate different approaches and use cases.

## Key Hook Primitives

### Access Control Mechanisms

1. **Signatures**
    - Use cryptographic signatures to verify the authenticity of messages or documents.
    - Example: Require a valid signature from an authorized account to approve transactions.

2. **Zero-Knowledge Proofs**
    - Implement cryptographic proofs that allow one party to prove the validity of a statement without revealing any additional information.
    - Example: Prove ownership of a private key without revealing the key itself.

3. **Attestations**
    - Utilize statements or claims made by an entity about a subject, which can be verified by others.
    - Example: Use attestations to confirm the identity of a user or the validity of a transaction.

4. **Allow/deny lists**
    - Set or maintain lists of allowed or denied addresses for nota interaction
    - Example: Disallow sanctioned addresses from being transferred notas and/or prevent sales on secondary markets.

5. **Ownable**
    - Implement ownership mechanisms to control access to certain actions or functions.
    - Example: Restrict the ability to mint new notas to the contract owner.

#### Use-cases
- KYC/AML of sending/receiving funds by checking the from and to accounts.
- Trust-minimized payment management by 3rd parties or subcommittees

### Time-Based Conditions

1. **Timelocks**
    - Implement time-based restrictions on certain actions.
    - Example: Funds can only be withdrawn after a specific date.

2. **Linear Unlock**
    - Gradually unlock funds over a specified period.
    - Example: Vesting schedules for token distributions.

2. **Expiration Dates**
    - Allow funds to be clawed back before or after an expiration date
    - Example: 

#### Use-cases
- Minimize trust by having a default unlock/return of funds after some expiration date

### Metadata Management

1. **Dynamic Metadata**
    - Update metadata dynamically based on contract state.
    - Example: Update token attributes based on external data.
2. **Metadata Requirements**
    - Require specific metadata to be set before an action can be performed.
    - Example: Require a title, description, and image to be set before a nota can be minted.

3. **Metadata Access Control**
    - Implement access control mechanisms based on metadata.
    - Example: Restrict access to certain actions based on metadata attributes.

4. **Hook Specific Metadata**
    - Use metadata to set hook-specific variables
    - Example: Set a settlement delay, administrator, or other hook-specific variables in metadata that can be displayed in the tokenURI

### External Contract Conditions

1. **Boolean Conditions**
    - Execute actions based on boolean conditions.
    - Example: Release funds only if a certain condition is met.

2. **Threshold Conditions**
    - Execute actions based on numerical thresholds.
    - Example: Release funds if a certain value exceeds a threshold.

#### Use-cases
- Enforce memos be set before a creating a nota

### Miscellaneous

1. **(Un)conditional (non)transferability**
    - Allow or disallow the transfer of notas based on certain conditions.
    - Example: Restrict transfers until a timelock expires.

2. **Counters**
    - Implement counters to track the number of interactions.
    - Example: Limit the number of times a user can perform a specific action.

### Fee Mechanisms

1. **Enforced Royalties**
    - Implement royalty mechanisms to ensure creators receive a share of secondary sales.
    - Example: Automatically distribute royalties to creators when a nota is transferred.

## Key Hook Patterns

### State
1. **Stateless**
- The hook stores no data it just validates parameters

2. **Isolated State**
- Each nota's data is the only relevant parameters for its ability to be created or interacted with

3. **Global State**
- Notas depend on global state which lives either inside the hook or referencing other contracts

### Conditions
1. **Nota Specific**
- Each nota can set it's variables on write such as expiration date, arbitrator, etc

2. **Hook Specific**
- Every Nota uses the hook-encoded variables such as settlement delay, administrator, etc

### Fee Structures
1. **Fixed Fees**
    - Implement fixed fee structures for transactions.
    - Example: Charge a fixed fee for each transaction.

2. **Dynamic Fees**
    - Implement dynamic fee structures based on caller, action, or other conditions.
    - Example: Charge different fees based on the type of action performed or the user's role.

#### Use-cases
- Implementing a flexible fee system that adjusts based on user actions or roles.

## Example Implementations
### [BaseHook.sol](./BaseHook.sol)

The `BaseHook` contract provides a template for creating custom hooks. It includes default implementations for various hook functions, which can be overridden by derived contracts.

### [LinearUnlock.sol](./hooks/examples/LinearUnlock.sol)

The `LinearUnlockHook` contract demonstrates a time-based unlocking mechanism. Funds are gradually unlocked over a specified period, and the amount that can be claimed increases linearly with time.

### [Metadata.sol](./hooks/examples/Metadata.sol)

The `Metadata` contract shows how to manage dynamic metadata for tokens. It allows setting and updating attributes, images, titles, names, external URLs, and descriptions.

### [SignatureRelease.sol](./hooks/examples/SignatureRelease.sol)

The `SignatureRelease` contract requires a valid signature from a specific address to authorize fund withdrawals. This ensures that only authorized parties can release funds.

### [ConditionalCash.sol](./hooks/examples/ConditionalCash.sol)

The `ConditionalCash` contracts demonstrate various conditional logic mechanisms. For example, the `BoolConditionalCash` contract releases funds based on boolean conditions, while the `GTConditionalCash` contract uses numerical thresholds.

### [ReversibleByBeforeDate.sol](./hooks/examples/ReversibleByBeforeDate.sol)

The `ReversibleByBeforeDate` contract allows an inspector to reverse payments during an inspection period. After the inspection period, only the owner can receive the funds.

### [HatsReversibleRelease.sol](./hooks/examples/HatsReversibleRelease.sol)

The `HatsReversibleRelease` contract integrates with the Hats Protocol to manage access control. It allows payments to be reversed by users wearing specific hats (roles).

## Conclusion

By leveraging these key hook primitives and example implementations, developers can create robust and flexible hooks tailored to their specific needs. Whether it's implementing access control, time-based conditions, or dynamic metadata, the possibilities are vast and can be customized to fit various use cases.