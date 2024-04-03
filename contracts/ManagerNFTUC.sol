//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./XUniversalBase.sol";
import "./PolyERC721UC.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./IPolyERC20.sol";

contract ManagerNFTUC is XUniversalBase, ERC721, ERC721Burnable {
    event BurnAckReceived(address receiver, uint256 tokenId, string message);
    event ReturnAckReceived(address receiver, uint256 tokenId, string message);
    PolyERC721UC public polyERC721;
    IPolyERC20 public polyERC20;

    constructor(
        address polyERC721Address,
        address polyERC20Address,
        address _middleware
    ) XUniversalBase(_middleware) {
        polyERC20 = IPolyERC20(polyERC20Address);
        polyERC721 = PolyERC721UC(polyERC721Address);
    }

    function burn(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        uint256 tokenId
    ) public virtual {
        polyERC721.burn(tokenId);
        PacketNFT memory burnNFT = PacketNFT(
            tokenTypeMap[tokenId],
            tokenId,
            msg.sender,
            IbcPacketStatus.UNSENT
        );
        bytes memory payload = abi.encode(
            IbcPacketType.BURN_NFT,
            abi.encode(burnNFT)
        );
        _sendUniversalPacket(destPortAddr, channelId, timeoutSeconds, payload);
    }

    function returnNFT(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        uint256 tokenId
    ) external {
        PacketNFT memory packet = PacketNFT(
            tokenTypeMap[tokenId],
            tokenId,
            msg.sender,
            IbcPacketStatus.UNSENT
        );
        bytes memory payload = abi.encode(
            IbcPacketType.RETURN_NFT,
            abi.encode(packet)
        );
        // Todo get nft from sender
        _sendUniversalPacket(destPortAddr, channelId, timeoutSeconds, payload);
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
        (IbcPacketType packetType, address caller, NFTType nftType) = abi
            .decode(ack.data, (IbcPacketType, address, NFTType));
        uint256 tokenId = polyERC721.mint(caller, nftType);
        bytes memory payload = abi.encode(packetType, caller, tokenId);
        return AckPacket(true, packet.appData);
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

        (IbcPacketType packetType, bytes memory data) = abi.decode(
            ack.data,
            (IbcPacketType, bytes)
        );
        if (packetType == IbcPacketType.BURN_NFT) {
            PacketNFT memory burnNFT = abi.decode(data, (PacketNFT));
            emit BurnAckReceived(
                burnNFT.recipient,
                burnNFT.tokenId,
                "NFT burned successfully"
            );
        } else if (packetType == IbcPacketType.RETURN_NFT) {
            PacketNFT memory returnNFT = abi.decode(data, (PacketNFT));
            emit ReturnAckReceived(
                returnNFT.recipient,
                returnNFT.tokenId,
                "NFT returned successfully"
            );
        } else if (packetType == IbcPacketType.MINT_NFT) {
            PacketNFT memory minNFT = abi.decode(data, (PacketNFT));
            emit MintAckReceived(
                minNFT.recipient,
                minNFT.tokenId,
                "NFT minted successfully"
            );
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
