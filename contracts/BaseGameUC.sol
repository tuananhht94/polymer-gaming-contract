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
    mapping(address => mapping(NFTType => uint256[])) internal _ownerTokenMap;
    mapping(NFTType => uint256[]) internal _typeTokenMap;

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

    function ownerTokenMap(
        address owner,
        NFTType pType
    ) external view returns (uint256[] memory) {
        return _ownerTokenMap[owner][pType];
    }

    function typeTokenMap(
        NFTType pType
    ) external view returns (uint256[] memory) {
        return _typeTokenMap[pType];
    }

    function tokenTypeMap(uint256 tokenId) external view returns (NFTType) {
        return _tokenTypeMap[tokenId];
    }

    function addToken(address recipient, uint256 tokenId, NFTType pType) internal {
        _tokenTypeMap[tokenId] = pType;
        _ownerTokenMap[recipient][pType].push(tokenId);
        _typeTokenMap[pType].push(tokenId);
    }

    function deleteToken(uint256 tokenId) internal {
        NFTType tokenType = _tokenTypeMap[tokenId];
        delete _tokenTypeMap[tokenId];

        uint256[] storage ownerTokens = _ownerTokenMap[msg.sender][tokenType];
        for (uint256 i = 0; i < ownerTokens.length; i++) {
            if (ownerTokens[i] == tokenId) {
                if (i != ownerTokens.length - 1) {
                    ownerTokens[i] = ownerTokens[ownerTokens.length - 1];
                }
                ownerTokens.pop();
                break;
            }
        }

        uint256[] storage typeTokens = _typeTokenMap[tokenType];
        for (uint256 i = 0; i < typeTokens.length; i++) {
            if (typeTokens[i] == tokenId) {
                if (i != typeTokens.length - 1) {
                    typeTokens[i] = typeTokens[typeTokens.length - 1];
                }
                typeTokens.pop();
                break;
            }
        }
    }
}
