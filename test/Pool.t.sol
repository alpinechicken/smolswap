// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {Test} from "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";
import {Swap} from "../src/Swap.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice mock token for testing
contract MockToken is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 1_000_000e18);
    }
}

/// @notice test suite for pool functionality
contract PoolTest is Test {
    Pool public pool;
    Swap public swap;
    MockToken public tokenA;
    MockToken public tokenB;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        // deploy tokens
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");

        // deploy pool
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        pool = new Pool("Pool", "POOL", tokens);

        // deploy swap
        swap = new Swap();

        // add swap to allowlist
        pool.addToAllowList(address(swap));

        // give tokens to alice and bob
        tokenA.transfer(alice, 1_000e18);
        tokenB.transfer(alice, 1_000e18);
        tokenA.transfer(bob, 1_000e18);
        tokenB.transfer(bob, 1_000e18);
    }

    /// @notice tests initial pool deposit
    function test_initialize_setsCorrectBalances() public {
        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // initial deposit
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100e18;
        amounts[1] = 100e18;
        swap.initialize(address(pool), amounts);

        // check balances
        assertEq(pool.balanceOf(alice), 1e18, "alice should receive 1e18 pool tokens");
        assertEq(tokenA.balanceOf(address(pool)), 100e18, "pool should have 100e18 tokenA");
        assertEq(tokenB.balanceOf(address(pool)), 100e18, "pool should have 100e18 tokenB");
        assertEq(tokenA.balanceOf(alice), 900e18, "alice should have 900e18 tokenA remaining");
        assertEq(tokenB.balanceOf(alice), 900e18, "alice should have 900e18 tokenB remaining");
    }

    /// @notice tests subsequent deposit after initialization
    function test_deposit_afterInitialize_setsCorrectBalances() public {
        // do initial deposit
        test_initialize_setsCorrectBalances();

        vm.startPrank(bob);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // subsequent deposit
        swap.deposit(address(pool), address(tokenA), 50e18);

        // check balances
        assertEq(pool.balanceOf(bob), 0.5e18, "bob should receive 0.5e18 pool tokens");
        assertEq(tokenA.balanceOf(address(pool)), 150e18, "pool should have 150e18 tokenA");
        assertEq(tokenB.balanceOf(address(pool)), 150e18, "pool should have 150e18 tokenB");
        assertEq(tokenA.balanceOf(bob), 950e18, "bob should have 950e18 tokenA remaining");
        assertEq(tokenB.balanceOf(bob), 950e18, "bob should have 950e18 tokenB remaining");
    }

    /// @notice tests withdrawing tokens from pool
    function test_withdraw_removesCorrectAmount() public {
        // do initial deposit
        test_initialize_setsCorrectBalances();

        vm.startPrank(alice);

        // approve pool tokens
        pool.approve(address(swap), type(uint256).max);

        // withdraw half
        swap.withdraw(address(pool), 0.5e18);

        // check balances
        assertEq(pool.balanceOf(alice), 0.5e18, "alice should have 0.5e18 pool tokens remaining");
        assertEq(tokenA.balanceOf(address(pool)), 50e18, "pool should have 50e18 tokenA");
        assertEq(tokenB.balanceOf(address(pool)), 50e18, "pool should have 50e18 tokenB");
        assertEq(tokenA.balanceOf(alice), 950e18, "alice should have 950e18 tokenA");
        assertEq(tokenB.balanceOf(alice), 950e18, "alice should have 950e18 tokenB");
    }

    /// @notice tests valid token reallocation
    function test_reallocate_validChangesBalances() public {
        // do initial deposit
        test_initialize_setsCorrectBalances();

        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // reallocate tokens
        int256[] memory deltas = new int256[](2);
        deltas[0] = 10e18; // deposit 10 tokenA
        deltas[1] = -5e18; // withdraw 5 tokenB

        swap.reallocate(address(pool), deltas);

        // check balances
        assertEq(tokenA.balanceOf(address(pool)), 110e18, "pool should have 110e18 tokenA after deposit");
        assertEq(tokenB.balanceOf(address(pool)), 95e18, "pool should have 95e18 tokenB after withdrawal");
    }

    /// @notice tests invalid reallocation that would violate invariant
    function test_reallocate_invalid_reverts() public {
        // do initial deposit
        test_initialize_setsCorrectBalances();

        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // reallocate tokens (invalid - would violate invariant)
        int256[] memory deltas = new int256[](2);
        deltas[0] = -90e18; // withdraw 90 tokenA
        deltas[1] = -90e18; // withdraw 90 tokenB

        vm.expectRevert(Pool.InvariantViolated.selector);
        swap.reallocate(address(pool), deltas);
    }

    /// @notice tests that initialize cannot be called twice
    function test_initialize_secondCall_reverts() public {
        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // first initialize
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100e18;
        amounts[1] = 100e18;
        swap.initialize(address(pool), amounts);

        // try to initialize again
        vm.expectRevert(Swap.NotAllowed.selector);
        swap.initialize(address(pool), amounts);
    }

    /// @notice tests that initialize reverts with zero amount
    function test_initialize_zeroAmount_reverts() public {
        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // try to initialize with zero amount
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100e18;
        amounts[1] = 0;
        vm.expectRevert(Swap.ZeroAmount.selector);
        swap.initialize(address(pool), amounts);
    }

    /// @notice tests that initialize reverts with invalid amounts length
    function test_initialize_invalidLength_reverts() public {
        vm.startPrank(alice);

        // approve tokens
        tokenA.approve(address(swap), type(uint256).max);
        tokenB.approve(address(swap), type(uint256).max);

        // try to initialize with wrong number of amounts
        int256[] memory amounts = new int256[](1);
        amounts[0] = 100e18;
        vm.expectRevert(Swap.InvalidAmountsLength.selector);
        swap.initialize(address(pool), amounts);
    }
}
