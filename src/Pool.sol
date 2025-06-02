// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import {IPool} from "./interface/IPool.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Pool is Ownable, ERC20, IPool {
    using Math for uint256;

    error NotAllowed();
    error InvariantViolated();
    error NegativeBalance();

    /// @notice token addresses
    address[] public addresses;
    /// @notice pool invariant
    uint256 public invariant;
    mapping(address => bool) public allowList;

    constructor(string memory _name, string memory _symbol, address[] memory _addresses)
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        addresses = _addresses;
    }

    function addressesLength() external view returns (uint256) {
        return addresses.length;
    }

    function addToAllowList(address _address) public onlyOwner {
        allowList[_address] = true;
        // approve swap contract to transfer tokens
        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20(addresses[i]).approve(_address, type(uint256).max);
        }
    }

    function reallocate(int256[] memory _deltas) public {
        uint256 newInvariant = _invariant(_deltas);
        if (newInvariant < invariant) revert InvariantViolated();
        invariant = newInvariant;
    }

    function _invariant(int256[] memory _deltas) internal view returns (uint256) {
        // constant product invariant
        uint256 sum;
        for (uint256 i = 0; i < _deltas.length; i++) {
            uint256 balance = IERC20(addresses[i]).balanceOf(address(this));
            int256 newBalance = int256(balance) + _deltas[i];
            if (newBalance < 0) revert NegativeBalance();
            sum += Math.log2(uint256(newBalance));
        }
        return sum;
    }

    function mint(address _to, uint256 _amount) public {
        if (!allowList[msg.sender]) {
            revert NotAllowed();
        }
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        if (!allowList[msg.sender]) {
            revert NotAllowed();
        }
        _burn(_from, _amount);
    }

    // function beforeSwap() {
    //     // TODO: Implement beforeSwap logic
    // }

    // function afterSwap() {
    //     // TODO: Implement afterSwap logic
    // }

    // function beforeDeposit() {
    //     // TODO: Implement beforeDeposit logic
    // }
    // function afterDeposit() {
    //     // TODO: Implement afterDeposit logic
    // }

    // function beforeWithdraw() {
    //     // TODO: Implement beforeWithdraw logic
    // }
    // function afterWithdraw() {
    //     // TODO: Implement afterWithdraw logic
    // }
}
