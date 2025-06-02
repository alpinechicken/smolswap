// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

interface IPool {
    // check invariant
    function reallocate(int256[] memory _deltas) external;
    function addresses(uint256 index) external view returns (address);
    function addressesLength() external view returns (uint256);
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    // // hooks
    // function beforeSwap() external;
    // function afterSwap() external;
    // function beforeDeposit() external;
    // function afterDeposit() external;
    // function beforeWithdraw() external;
    // function afterWithdraw() external;
}
