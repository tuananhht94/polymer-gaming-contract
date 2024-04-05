//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./BaseGameUC.sol";

contract PolyERC721UC is BaseGameUC, ERC721 {
    uint256 public currentTokenId = 0;
    mapping(NFTType => string) public tokenURIs;
    string public tokenURIC4 =
        "https://emerald-uncertain-cattle-112.mypinata.cloud/ipfs/QmZu7WiiKyytxwwKSwr6iPT1wqCRdgpqQNhoKUyn1CkMD3";

    constructor(
        address _middleware
    ) BaseGameUC(_middleware) ERC721("PolymerNFT", "POLY") {
        tokenURIs[
            NFTType.POLY1
        ] = "https://media.discordapp.net/attachments/1222189690816565328/1225547538548129802/DALLE_2024-04-04_12.53.18_-_Create_an_image_of_a_fluffy_orange_adventurous_creature_resembling_an_intrepid_explorer._The_creature_should_have_large_eyes_a_bright_and_determine.webp?ex=66218716&is=660f1216&hm=1afd67dc360792fb98ac18d951c618ba430776280e34866e27fbd21e8e60865b&=&format=webp&width=1288&height=1288";
        tokenURIs[
            NFTType.POLY2
        ] = "https://media.discordapp.net/attachments/1222189690816565328/1225547539374276628/de1c9b4f-fe72-4c6f-b8bc-1e6fa8713fea.webp?ex=66218716&is=660f1216&hm=9054ebbb64f1a3d66b55ffe815678a9e79d0707d2e35899d64a905dff697c366&=&format=webp&width=1288&height=1288";
        tokenURIs[
            NFTType.POLY3
        ] = "https://media.discordapp.net/attachments/1222189690816565328/1225547539953221643/f741ee99-e48c-4846-9b00-2ba08aafc3e8.webp?ex=66218717&is=660f1217&hm=36479489436ae36f38ffeb2c03e874674cae86cc005fa14fb9c4fa4597b0476f&=&format=webp&width=1288&height=1288";
        tokenURIs[
            NFTType.POLY4
        ] = "https://media.discordapp.net/attachments/1222189690816565328/1225547540460601506/polymer_pomeranian.png?ex=66218717&is=660f1217&hm=44a263a8f36530a11164d61d820af176b65149747df3532d4adb8b580e526be9&=&format=webp&quality=lossless&width=1288&height=1288";
    }

    function mint(address recipient, NFTType pType) internal returns (uint256) {
        currentTokenId += 1;
        uint256 tokenId = currentTokenId;
        _tokenTypeMap[tokenId] = pType;
        _ownerTokenMap[recipient].push(tokenId);
        _typeTokenMap[pType].push(tokenId);
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function burn(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        _burn(tokenId);
        // delete _tokenTypeMap[tokenId];
        // delete _ownerTokenMap[msg.sender][tokenId];
        // delete _typeTokenMap[_tokenTypeMap[tokenId]];
        _sendUniversalPacket(
            destPortAddr,
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.BURN_NFT, abi.encode(msg.sender, tokenId))
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("Transfer not allowed");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return tokenURIs[_tokenTypeMap[tokenId]];
    }

    function updateTokenURI(string memory _newTokenURI) public {
        tokenURIC4 = _newTokenURI;
    }

    function getTokenId() public view returns (uint256) {
        return currentTokenId;
    }

    function randomMint(address recipient) public returns (uint256, NFTType) {
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 100;
        NFTType pType = NFTType.POLY1;
        if (random >= 50 && random < 75) {
            pType = NFTType.POLY2;
        } else if (random >= 75 && random < 95) {
            pType = NFTType.POLY3;
        } else if (random >= 95) {
            pType = NFTType.POLY4;
        }
        uint256 tokenId = mint(recipient, pType);
        return (tokenId, pType);
    }

    function getRandomNumber(
        uint256 min,
        uint256 max
    ) public view returns (uint256) {
        require(min <= max, "Invalid range");
        uint256 blockValue = uint256(blockhash(block.number - 1));
        return
            (uint256(keccak256(abi.encodePacked(blockValue, block.timestamp))) %
                (max - min + 1)) + min;
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

        (IbcPacketType packageType, bytes memory data) = abi.decode(
            packet.appData,
            ((IbcPacketType), bytes)
        );

        if (packageType == IbcPacketType.FAUCET) {
            address caller = abi.decode(data, (address));
            uint256 amount = getRandomNumber(1, 10);
            return
                AckPacket(
                    true,
                    abi.encode(packageType, abi.encode(caller, amount))
                );
        } else if (packageType == IbcPacketType.BUY_NFT) {
            (address caller, NFTType nftType) = abi.decode(
                data,
                (address, NFTType)
            );
            uint256 tokenId = mint(caller, nftType);
            return
                AckPacket(
                    true,
                    abi.encode(
                        packageType,
                        abi.encode(caller, nftType, tokenId)
                    )
                );
        } else if (packageType == IbcPacketType.BUY_RANDOM_NFT) {
            address caller = abi.decode(data, (address));
            (uint256 tokenId, NFTType nftType) = randomMint(caller);
           return
                AckPacket(
                    true,
                    abi.encode(
                        packageType,
                        abi.encode(caller, nftType, tokenId)
                    )
                );
        } else {
            revert("Invalid packet type");
        }
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
//        (IbcPacketType packetType, bytes memory data) = abi.decode(
//            ack.data,
//            (IbcPacketType, bytes)
//        );

//        if (packetType == IbcPacketType.BURN_NFT) {
//            (address caller, uint256 tokenId) = abi.decode(
//                data,
//                (address, uint256)
//            );
//        }
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
