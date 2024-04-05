// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPolyERC20 is IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}
