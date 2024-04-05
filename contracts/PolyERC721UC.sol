//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./BasePolyERC721.sol";

contract PolyERC721UC is UniversalChanIbcApp, BasePolyERC721 {
    event MintAckReceived(address receiver, uint256 tokenId, string message);
    event NFTAckReceived(address voter, address recipient, uint256 voteId);

    constructor(address _middleware) UniversalChanIbcApp(_middleware) BasePolyERC721() {
    }

    function randomMint(address recipient) public {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        NFTType pType = NFTType.POLY1;
        if (random >= 50 && random < 75) {
            pType = NFTType.POLY2;
        } else if (random >= 75 && random < 95) {
            pType = NFTType.POLY3;
        } else if (random >= 95) {
            pType = NFTType.POLY4;
        }
        mint(recipient, pType);
    }

    function crossChainMint(address destPortAddr, bytes32 channelId, uint64 timeoutSeconds, NFTType tokenType)
    external
    {
        bytes memory payload = abi.encode(msg.sender, tokenType);
        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        // Check if they have enough Polymer Testnet Tokens to mint the NFT
        // If not Revert

        // Burn the Polymer Testnet Tokens from the sender

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
    external
    override
    onlyIbcMw
    returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address _caller, NFTType tokenType) = abi.decode(packet.appData, (address, NFTType));

        uint256 tokenId = mint(_caller, tokenType);

        return AckPacket(true, abi.encode(_caller, tokenId));
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
    external
    override
    onlyIbcMw
    {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        // decode the counter from the ack packet
        (address caller, uint256 tokenId) = abi.decode(ack.data, (address, uint256));

        emit MintAckReceived(caller, tokenId, "NFT minted successfully");
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
