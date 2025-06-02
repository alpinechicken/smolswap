# Solidity Style Guide

## Table of Contents

1. [Code Layout](#1-code-layout)
2. [Naming Conventions](#2-naming-conventions)
3. [Code Style](#3-code-style)
4. [Testing](#4-testing)
5. [Documentation](#5-documentation)
6. [Gas Optimization](#6-gas-optimization)
7. [References](#7-references)

## 1. Code Layout

### A. File Structure

1. SPDX license identifier
2. Pragma statements
3. Imports (grouped and ordered)
4. Custom errors
5. Contract declaration

### B. Interface Structure

#### General Rules

- All events and structs should be defined in interfaces, not implementation contracts
- Keep interfaces focused and specific to a single concern
- Interfaces should fully describe the contract's public API

#### Ordering in Interface

1. Event declarations
2. Struct definitions
3. Function declarations

Example:

```solidity
// IToken.sol
interface IToken {
    /// @notice emitted when tokens are transferred
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);

    /// @notice represents a stake position
    struct StakePosition {
        uint40 timestamp;
        uint256 amount;
    }

    function transfer(address to, uint256 amount) external returns (bool);
}

// Token.sol
import { IToken } from "./interfaces/IToken.sol";

contract Token is IToken {
    // implementation only - no event or struct definitions here
    function transfer(address to, uint256 amount) external returns (bool) {
        // implementation
        emit TokensTransferred(msg.sender, to, amount);
    }
}
```

### C. Contract Structure

1. State variables
2. Constructor
3. Receive function (if exists)
4. Fallback function (if exists)
5. External functions
6. Public functions
7. Internal functions
8. Private functions

Within each visibility group:

- View/pure functions should come last

## 2. Naming Conventions

### A. General

- Use meaningful and descriptive names
- Use PascalCase for contract names, struct names, event names, custom error names
- Use camelCase for function names and variable names
- Use UPPER_CASE for constants
- Avoid names that differ only by capitalization

### B. Files

- One contract per file
- Contract file names should match contract name
- Use `.sol` extension
- Test files should have `.t` before `.sol` (e.g., `ERC20.t.sol`)
- Script files should have `.s` before `.sol` (e.g., `Deploy.s.sol`)

### C. Function Names

Function names should be action-based verbs. Common patterns:

```solidity
// asset operations
transfer()          // move assets
transferFrom()      // move assets on behalf
mint()              // create new tokens
burn()              // destroy tokens
deposit()           // add assets
withdraw()          // remove assets

// bad examples
tokensTransfer()     // not verb-first
doTransferTokens()   // redundant 'do'
tokenTransferring()  // not imperative
```

### D. Variables

- Arrays: plural form (e.g., `users`, `amounts`)
- Mappings: descriptive of key and value (`addressToBalance`)
- Boolean: prefix with `is`, `has`, `can` (e.g., `isActive`)
- Timestamps in structs: use uint40 (or at least uint32)

### E. Internal/Private Naming

1. Internal and private functions should be prefixed with an underscore:

```solidity
// good
function _transfer(address _from, address _to, uint256 _amount) internal {
    // implementation
}

function _validateAmount(uint256 _amount) private pure {
    // implementation
}

// bad
function transfer(address _from, address _to, uint256 _amount) internal {
    // implementation
}
```

2. Internal and private state variables should be prefixed with an underscore:

```solidity
// good
uint256 private _totalSupply;
mapping(address => uint256) internal _balances;

// bad
uint256 private totalSupply;
mapping(address => uint256) internal balances;
```

3. Function parameters should be prefixed with an underscore:

```solidity
// good
function transfer(address _to, uint256 _amount) external returns (bool) {
    // implementation
}

function initialize(string memory _name, string memory _symbol) external {
    // implementation
}

// bad
function transfer(address to, uint256 amount) external returns (bool) {
    // implementation
}
```

4. Exceptions:

- Library functions should NOT use underscore prefix (as noted in the Library Functions section)
- Constants should use UPPER_CASE regardless of visibility
- Immutable variables should not use underscore prefix

### F. Library Functions

Internal library functions should not use underscore prefix because:

1. These functions are meant to be called from other contracts
2. Underscore prefix creates awkward code: `Library._function()`
3. "Internal use only" indication isn't relevant for library functions

### G. Events

- Use past tense
- Follow `SubjectVerb` format

```solidity
// good
event TokensBurned(address indexed from, uint256 amount);
event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

// bad
event BurnTokens(address indexed from, uint256 amount);
event UpdateOwner(address indexed oldOwner, address indexed newOwner);
```

### H. Errors

Examples by category:

```solidity
// access control
error Unauthorized(address caller);
error OperatorNotApproved(address operator);
error CallerNotOwner(address caller, address owner);

// input validation
error AmountTooLow(uint256 minimum, uint256 provided);
error AmountTooHigh(uint256 maximum, uint256 provided);
error InvalidAddress(address provided);
error DeadlinePassed(uint256 deadline, uint256 timestamp);

// state validation
error ContractPaused();
error AlreadyInitialized();
error NotInitialized();

// asset operations
error InsufficientBalance(uint256 required, uint256 balance);
error InsufficientAllowance(uint256 required, uint256 allowance);
error TransferFailed(address token, address from, address to);
```

## 3. Code Style

### A. Imports

Group imports in this order with line breaks between groups:

```solidity
// external interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// internal interfaces
import { IMyToken } from "./interfaces/IMyToken.sol";
import { IVault } from "./interfaces/IVault.sol";

// external libraries
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// internal libraries
import { ErrorLib } from "./libraries/ErrorLib.sol";
import { ValidationLib } from "./libraries/ValidationLib.sol";

// external contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// internal contracts
import { BaseToken } from "./BaseToken.sol";
import { Vault } from "./Vault.sol";
```

### B. Function Parameters

Use named arguments when improving clarity:

```solidity
function setPower({
    uint256 base,
    uint256 exponent,
    uint256 modulus
}) external returns (uint256)
```

### C. Numbers

Use underscore separators for readability:

```solidity
uint256 private constant LARGE_NUMBER = 1_000_000_000;
```

### D. Mappings

Use named parameters:

```solidity
mapping(address owner => mapping(address token => uint256 balance)) public balances;
```

## 4. Testing

### A. Organization

- Test files end with `.t.sol`
- One behavior per test
- Test contract names: `ContractNameTest` or `FunctionNameTest`

### B. Naming Convention

1. Regular Tests:
   - Function names: `test_functionName_outcome_optionalContext`
   - Always start with `test_`

```solidity
function test_transferFrom_debitsFromAccountBalance() public {}
function test_transferFrom_reverts_whenAmountExceedsBalance() public {}
function test_transferFrom_emitsEvent_whenSuccessful() public {}
```

2. Fuzz Tests:
   - Function names: `testFuzz_functionName_outcome_optionalContext`
   - Always start with `testFuzz_`
   - Parameters should be well-bounded to avoid unrealistic values

```solidity
// good
function testFuzz_transferFrom_creditsTo(uint256 amount) public {
    vm.assume(amount > 0 && amount < MAX_AMOUNT);
    assertEq(balanceOf(recipient), 0);
    transferFrom(sender, recipient, amount);
    assertEq(balanceOf(recipient), amount);
}

// good - multiple parameters
function testFuzz_swap_correctAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
) public {
    vm.assume(amountIn > 0 && amountIn <= MAX_AMOUNT);
    vm.assume(reserveIn > 0 && reserveIn <= MAX_RESERVE);
    vm.assume(reserveOut > 0 && reserveOut <= MAX_RESERVE);
    // test implementation
}

// bad - no testFuzz prefix
function test_transferFrom_fuzzing(uint256 amount) public {
    // implementation
}

// bad - unbounded parameters
function testFuzz_transferFrom_noAssumptions(uint256 amount) public {
    // implementation without bounds checking
}
```

### C. Best Practices

- Use descriptive variables instead of magic numbers
- Prefer fuzz tests over fixed values
- Keep tests focused and isolated

Example:

```solidity
function test_transferFrom_creditsTo(uint256 amount) public {
    assertEq(balanceOf(recipient), 0);
    transferFrom(sender, recipient, amount);
    assertEq(balanceOf(recipient), amount);
}
```

## 5. Documentation

### A. General Comments

- All comments should be lowercase, including regular comments and NatSpec
- Use single-line comments for brief explanations
- Use multi-line comments for longer explanations

```solidity
// this is a single-line comment.

/*
 * this is a multi-line comment.
 * notice how everything is lowercase.
 * each line ends with a period.
 */
```

### B. NatSpec

- Use lowercase for all NatSpec comments
- Use multiline format
- Document all functions, events, errors, and structs

```solidity
/**
 * @notice transfers tokens to a specified address
 *
 * @dev implementation details and security considerations
 *
 * @param _to the recipient address
 * @param _amount the amount to transfer
 *
 * @return success true if transfer was successful
 */
function transfer(address _to, uint256 _amount) external returns (bool success)
```

### C. Struct Documentation

```solidity
/// @notice describes an account's position
struct Position {
    /// @dev timestamp when position was created
    uint40 timestamp;
    /// @dev amount of tokens in position
    uint256 amount;
}
```

## 6. Gas Optimization

### A. Storage

- Pack related storage variables
- Use uint256 unless smaller size needed
- Use bytes32 instead of string where possible
- Cache frequently accessed storage values

### B. Functions and Loops

- Use view/pure when possible
- Avoid unbounded loops
- Cache array lengths
- Use unchecked blocks for counters

### C. Memory vs Storage

- Use calldata for external function parameters
- Minimize storage reads and writes
- Cache storage variables when used multiple times

## 7. References

This style guide incorporates conventions and best practices from:

- [Official Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- [Coinbase Solidity Style Guide](https://github.com/coinbase/solidity-style-guide)
