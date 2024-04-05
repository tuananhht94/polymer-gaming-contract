//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./XGamingUCBase.sol";
import "./IPolyERC20.sol";
import "./BasePolyERC721.sol";

contract XGamingUC is XGamingUCBase {
    IPolyERC20 public polyERC20;
    event BuyNFTAckReceived(address recipient, uint256 nftId, string message);

    mapping(address => uint256) public latestFaucetTime;
    mapping(NFTType => uint256) public nftPrice;
    mapping(NFTType => uint256) public nftPoint;

    constructor(address _middleware) XGamingUCBase(_middleware) {
        // Init nft prices
        nftPrice[NFTType.POLY1] = 25;
        nftPrice[NFTType.POLY2] = 50;
        nftPrice[NFTType.POLY3] = 75;
        nftPrice[NFTType.POLY4] = 100;
        // Init nft points
        nftPoint[NFTType.POLY1] = 10;
        nftPoint[NFTType.POLY2] = 50;
        nftPoint[NFTType.POLY3] = 150;
        nftPoint[NFTType.POLY4] = 500;
    }

    function setPolyERC20Address(address _polyERC20) external onlyOwner {
        polyERC20 = IPolyERC20(_polyERC20);
    }

    function faucetToken(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external {
        require(
            block.timestamp >= latestFaucetTime[msg.sender] + 5 minutes,
            "Faucet: Too soon"
        );
        latestFaucetTime[msg.sender] = block.timestamp;

        _sendUniversalPacket(
            destPortAddr,
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.FAUCET, abi.encode(msg.sender))
        );
    }

    function buyNFT(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        NFTType nftType
    ) public {
        require(
            polyERC20.allowance(msg.sender, address(this)) >= nftPrice[nftType],
            "Insufficient balance"
        );
        polyERC20.transferFrom(msg.sender, address(this), nftPrice[nftType] * 10 ** 18);
        // Mint NFT
        _sendUniversalPacket(
            destPortAddr,
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.BUY_NFT, abi.encode(msg.sender, nftType))
        );
    }

    function buyRandomNFT(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external {
        uint256 random = getRandomNumber(1, 10);
        NFTType nftType = NFTType.POLY1;
        if (random >= 5 && random < 7) {
            nftType = NFTType.POLY2;
        } else if (random >= 7 && random < 9) {
            nftType = NFTType.POLY3;
        } else if (random >= 9) {
            nftType = NFTType.POLY4;
        }
    }

    function getRandomNumber(
        uint256 min,
        uint256 max
    ) public view returns (uint256) {
        require(min <= max, "Invalid range");
        uint256 blockValue = uint256(blockhash(block.number - 1));
        return uint256(keccak256(abi.encodePacked(blockValue, block.timestamp))) % (max - min + 1) + min;
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));
        (IbcPacketType packetType, bytes memory data) = abi.decode(
            ackPacket.data,
            (IbcPacketType, bytes)
        );
        if (packetType == IbcPacketType.BURN_NFT) {
            PacketNFT memory burnNFT = abi.decode(data, (PacketNFT));
            _burnNFT(burnNFT);
        } else if (packetType == IbcPacketType.RETURN_NFT) {
            PacketNFT memory returnNFT = abi.decode(data, (PacketNFT));
            _returnNFT(returnNFT);
        } else {
            revert("Invalid packet type");
        }
        return AckPacket(true, packet.appData);
    }

    function _burnNFT(PacketNFT memory packet) internal {
        // TODO update Leaderboard points
    }

    function _returnNFT(PacketNFT memory packet) internal {
        // TODO: Implement logic to return NFT to the caller
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external override onlyIbcMw {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));
        (IbcPacketType packetType, bytes memory data) = abi.decode(ack.data, (IbcPacketType, bytes ));

        if (packetType == IbcPacketType.FAUCET) {
            (address caller, uint256 amount) = abi.decode(data, (address, uint256));
            polyERC20.mint(caller, amount * 10**18);
        } else if (packetType == IbcPacketType.BUY_NFT) {
            (address caller, NFTType nftType, uint256 tokenId) = abi.decode(data, (address, NFTType, uint256));
            tokenTypeMap[tokenId] = nftType;
            typeTokenMap[nftType].push(tokenId);
            polyERC20.burn(nftPrice[nftType]);
            emit BuyNFTAckReceived(caller, tokenId, "NFT bought successfully");
        } else {
            revert("Invalid packet type");
        }
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
