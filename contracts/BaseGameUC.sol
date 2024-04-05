//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./base/UniversalChanIbcApp.sol";

contract BaseGameUC is UniversalChanIbcApp {
    enum NFTType {
        POLY1,
        POLY2,
        POLY3,
        POLY4
    }

    mapping(uint256 => NFTType) internal _tokenTypeMap;
    mapping(address => uint256[]) internal _ownerTokenMap;
    mapping(NFTType => uint256[]) internal _typeTokenMap;

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

    function ownerTokenMap(
        address owner
    ) external view returns (uint256[] memory) {
        return _ownerTokenMap[owner];
    }

    function typeTokenMap(
        NFTType pType
    ) external view returns (uint256[] memory) {
        return _typeTokenMap[pType];
    }

    function tokenTypeMap(uint256 tokenId) external view returns (NFTType) {
        return _tokenTypeMap[tokenId];
    }
}
