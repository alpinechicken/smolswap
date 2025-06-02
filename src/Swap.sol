// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {IPool} from "./interface/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice contract for managing pool operations
contract Swap is ReentrancyGuard {
    using Math for uint256;

    /// @notice constant for share calculations
    uint256 private constant ONE = 1e18;

    /// @notice thrown when amount is zero
    error ZeroAmount();
    /// @notice thrown when balance is zero
    error ZeroBalance();
    /// @notice thrown when amounts array length is invalid
    error InvalidAmountsLength();
    /// @notice thrown when operation is not allowed
    error NotAllowed();

    /**
     * @notice initializes the pool with the first deposit
     * @param _pool address of the pool contract
     * @param _amounts array of token amounts to deposit
     */
    function initialize(address _pool, int256[] calldata _amounts) public nonReentrant {
        if (IERC20(_pool).totalSupply() != 0) revert NotAllowed();
        if (_amounts.length != IPool(_pool).addressesLength()) revert InvalidAmountsLength();

        // convert amounts to deltas for reallocate
        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] == 0) revert ZeroAmount();
        }

        // use reallocate to set initial invariant and transfer tokens
        reallocate(_pool, _amounts);

        // mint 1e18 shares to user
        IPool(_pool).mint(msg.sender, ONE);
    }

    /**
     * @notice reallocates tokens in the pool according to the deltas
     * @param _pool address of the pool contract
     * @param _deltas array of token deltas, positive for deposits, negative for withdrawals
     */
    function reallocate(address _pool, int256[] calldata _deltas) public {
        // update invariant in the pool or revert if invariant is violated
        IPool(_pool).reallocate(_deltas);

        for (uint256 i = 0; i < IPool(_pool).addressesLength(); i++) {
            if (_deltas[i] > 0) {
                IERC20(IPool(_pool).addresses(i)).transferFrom(msg.sender, _pool, uint256(_deltas[i]));
            } else if (_deltas[i] < 0) {
                // TODO: callback for flash loan
                IERC20(IPool(_pool).addresses(i)).transferFrom(_pool, msg.sender, uint256(-_deltas[i]));
            }
        }
    }

    /**
     * @notice deposits tokens into the pool and mints shares
     * @param _pool address of the pool contract
     * @param _token address of the token to use for share calculation
     * @param _amount amount of tokens to deposit
     */
    function deposit(address _pool, address _token, uint256 _amount) public nonReentrant {
        if (_amount == 0) revert ZeroAmount();

        uint256 totalSupply = IERC20(_pool).totalSupply();
        uint256 share;

        if (totalSupply == 0) {
            // first deposit gets 1e18 shares
            share = ONE;
        } else {
            // balance of anchor token
            uint256 balance = IERC20(_token).balanceOf(_pool);
            if (balance == 0) revert ZeroBalance();

            // share of the user
            share = ONE * _amount / balance;
        }
        // transfer tokens from user to pool
        for (uint256 i = 0; i < IPool(_pool).addressesLength(); i++) {
            address token = IPool(_pool).addresses(i);
            if (token == _token) {
                // transfer exact amount for anchor token
                IERC20(token).transferFrom(msg.sender, _pool, _amount);
            } else {
                // transfer proportional amount for other tokens
                uint256 balance = IERC20(token).balanceOf(_pool);
                uint256 transferAmount = (share * balance) / ONE;
                IERC20(token).transferFrom(msg.sender, _pool, transferAmount);
            }
        }

        // mint shares to user
        IPool(_pool).mint(msg.sender, totalSupply == 0 ? ONE : share * totalSupply / ONE);
    }

    /**
     * @notice withdraws tokens from the pool by burning shares
     * @param _pool address of the pool contract
     * @param _shares amount of shares to burn
     */
    function withdraw(address _pool, uint256 _shares) public nonReentrant {
        if (_shares == 0) revert ZeroAmount();
        uint256 totalSupply = IERC20(_pool).totalSupply();

        // burn user's shares
        IPool(_pool).burn(msg.sender, _shares);

        // transfer tokens from pool to user
        for (uint256 i = 0; i < IPool(_pool).addressesLength(); i++) {
            uint256 balance = IERC20(IPool(_pool).addresses(i)).balanceOf(_pool);
            IERC20(IPool(_pool).addresses(i)).transferFrom(_pool, msg.sender, (_shares * balance) / totalSupply);
        }
    }
}
