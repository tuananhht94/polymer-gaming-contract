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

    function _sendUniversalPacket(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        bytes memory payload
    ) internal {
        uint64 timeoutTimestamp = uint64(
            (block.timestamp + timeoutSeconds) * 1000000000
        );
        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(destPortAddr),
            payload,
            timeoutTimestamp
        );
    }
}
