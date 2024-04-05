//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasePolyERC721 is ERC721 {
    uint256 public currentTokenId = 0;
    string public tokenURIC4 =
    "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";

    enum NFTType {
        POLY1,
        POLY2,
        POLY3,
        POLY4
    }

    mapping(uint256 => NFTType) public tokenTypeMap;
    mapping(NFTType => string) public tokenURIs;
    mapping(NFTType => uint256[]) public typeTokenMap;

    constructor() ERC721("PolymerC4NFT", "POLY4") {
        tokenURIs[NFTType.POLY1] =
                    "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";
        tokenURIs[NFTType.POLY2] =
                    "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";
        tokenURIs[NFTType.POLY3] =
                    "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";
        tokenURIs[NFTType.POLY4] =
                    "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";
    }

    function mint(address recipient, NFTType pType) internal returns (uint256) {
        currentTokenId += 1;
        uint256 tokenId = currentTokenId;
        tokenTypeMap[tokenId] = pType;
        typeTokenMap[pType].push(tokenId);
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("Transfer not allowed");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return tokenURIs[tokenTypeMap[tokenId]];
    }

    function updateTokenURI(string memory _newTokenURI) public {
        tokenURIC4 = _newTokenURI;
    }

    function getTokenId() public view returns (uint256) {
        return currentTokenId;
    }
}
