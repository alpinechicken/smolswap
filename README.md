# SmolSwap

A minimal, gas-efficient constant function AMM (Automated Market Maker) implementation. SmolSwap is a toy implementation designed for testing integrations and experimenting with different invariant functions. It allows liquidity providers to deploy pools with arbitrary invariant functions, including concentrated liquidity positions.

## Features

- Arbitrary invariant function support (f(x) = k)
- Multi-token pool support
- Callback for flash loans (coming soon!)
- Hooks for {before, after}x{deposit, withdraw, reallocate} (coming soon!)

## Architecture

The protocol consists of a Swap contract and any number of Pool contracts:

### Pool Contract
- Manages token balances
- Enforces the invariant
- Handles share minting and burning
- Controls access to pool operations
- Can implement any invariant function (e.g., constant product, concentrated liquidity)

### Swap Contract
- Provides user-facing functions for pool operations
- Handles token transfers and share calculations
- Implements deposit, withdraw, and reallocate functions

## Usage Examples

### Creating and Initializing a Pool

```solidity
// Deploy tokens
MockToken tokenA = new MockToken("Token A", "TKNA");
MockToken tokenB = new MockToken("Token B", "TKNB");

// Deploy pool with tokens
address[] memory tokens = new address[](2);
tokens[0] = address(tokenA);
tokens[1] = address(tokenB);
Pool pool = new Pool("Pool", "POOL", tokens);

// Deploy swap contract
Swap swap = new Swap();

// Add swap to pool's allowlist
pool.addToAllowList(address(swap));

// Initialize pool with initial liquidity
int256[] memory amounts = new int256[](2);
amounts[0] = 100e18;  // 100 tokenA
amounts[1] = 100e18;  // 100 tokenB
swap.initialize(address(pool), amounts);
```

### Depositing Tokens

```solidity
// Approve tokens
tokenA.approve(address(swap), type(uint256).max);
tokenB.approve(address(swap), type(uint256).max);

// Deposit tokens using tokenA as anchor and matching shares for other tokens
swap.deposit(address(pool), address(tokenA), 50e18);
```

### Withdrawing Tokens

```solidity
// Approve pool tokens
pool.approve(address(swap), type(uint256).max);

// Withdraw half of your shares
swap.withdraw(address(pool), 0.5e18);
```

### Reallocating Tokens

```solidity
// Reallocate tokens (deposit tokenA, withdraw tokenB)
int256[] memory deltas = new int256[](2);
deltas[0] = 10e18;   // deposit 10 tokenA
deltas[1] = -5e18;   // withdraw 5 tokenB
swap.reallocate(address(pool), deltas);
```

## Development

### Prerequisites

- Foundry
- Node.js

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/smolswap.git
cd smolswap

# Install dependencies
forge install

# Run tests
forge test
```

## Dependencies

This project uses the following dependencies:
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - MIT License
- [Foundry](https://github.com/foundry-rs/foundry) - Apache-2.0 License

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
