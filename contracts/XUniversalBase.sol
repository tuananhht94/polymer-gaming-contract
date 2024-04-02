//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";

contract XUniversalBase is UniversalChanIbcApp {
    enum IbcPacketStatus {
        UNSENT,
        SENT,
        ACKED,
        TIMEOUT
    }

    enum NFTType {
        POLY1,
        POLY2,
        POLY3,
        POLY4
    }

    enum IbcPacketType {
        BURN_NFT,
        RETURN_NFT,
        MINT_NFT,
        BUY_NFT,
        BUY_RANDOM_NFT
    }

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
