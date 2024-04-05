//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

contract BasePolyERC721 {
    enum NFTType {
        POLY1,
        POLY2,
        POLY3,
        POLY4
    }

    mapping(uint256 => NFTType) public tokenTypeMap;
    mapping(NFTType => uint256[]) public typeTokenMap;
}
