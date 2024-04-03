// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPolyERC20 is IERC20 {
    function transferFrom(
        address destPortAddr,
        uint256 amount,
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external;
}
