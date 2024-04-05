//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "./BasePolyERC721.sol";

contract XGamingUCBase is BasePolyERC721, UniversalChanIbcApp {
    struct PacketNFT {
        NFTType nftType;
        uint256 tokenId;
        address recipient;
        IbcPacketStatus status;
    }

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}
}
