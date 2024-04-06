//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./IPolyERC20.sol";
import "./BaseGameUC.sol";

contract XGamingUC is BaseGameUC {
    IPolyERC20 public polyERC20;
    event BuyNFTAckReceived(address recipient, uint256 nftId, string message);

    mapping(address => uint256) public latestFaucetTime;
    mapping(NFTType => uint256) public nftPrice;
    mapping(NFTType => uint256) public nftPoint;
    uint256 public randomPriceBuyNFTAmount = 60;

    struct Player {
        uint256 score;
        uint256 index;
    }

    mapping(address => Player) public players;
    address[] public leaderboard;

    constructor(address _middleware) BaseGameUC(_middleware) {
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
        polyERC20.transferFrom(
            msg.sender,
            address(this),
            nftPrice[nftType] * 10 ** 18
        );
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
    ) public {
        uint256 amount = randomPriceBuyNFTAmount * 10 ** 18;
        require(
            polyERC20.allowance(msg.sender, address(this)) >= amount,
            "Insufficient balance"
        );
        polyERC20.transferFrom(msg.sender, address(this), amount);
        // Mint NFT
        _sendUniversalPacket(
            destPortAddr,
            channelId,
            timeoutSeconds,
            abi.encode(IbcPacketType.BUY_RANDOM_NFT, abi.encode(msg.sender))
        );
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
        (IbcPacketType packetType, bytes memory data) = abi.decode(
            packet.appData,
            (IbcPacketType, bytes)
        );
        if (packetType == IbcPacketType.BURN_NFT) {
            (address caller, uint256 tokenId) = abi.decode(data, (address, uint256));
            polyERC20.mint(caller, nftPrice[_tokenTypeMap[tokenId]] * 10 ** 18 * 20 / 100);
            deleteToken(tokenId);
            calculateUserPoint(caller);
        }

        return AckPacket(true, packet.appData);
    }

    function calculateUserPoint(address user) public {
        Player storage player = players[user];

        if (player.score == 0) {
            leaderboard.push(user);
            player.index = leaderboard.length;
        }

        uint256[] memory nftTypeCount = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            nftTypeCount[i] = _ownerTokenMap[user][NFTType(i)].length;
        }

        uint256 minNFT = nftTypeCount[0];
        for (uint256 i = 1; i < 4; i++) {
            if (nftTypeCount[i] < minNFT) {
                minNFT = nftTypeCount[i];
            }
        }

        player.score = minNFT * 2000;
        for (uint256 i = 0; i < 4; i++) {
            player.score += (nftTypeCount[i] - minNFT) * nftPoint[NFTType(i)];
        }

        uint256 currentIndex = player.index;
        while (currentIndex > 1 && players[leaderboard[currentIndex - 1]].score > player.score) {
            (leaderboard[currentIndex - 1], leaderboard[currentIndex]) = (leaderboard[currentIndex], leaderboard[currentIndex - 1]);
            players[leaderboard[currentIndex]].index = currentIndex;
            players[leaderboard[currentIndex - 1]].index = currentIndex - 1;
            currentIndex--;
        }
    }

    function getTopPlayers(uint256 _count) external view returns (address[] memory, uint256[] memory) {
        uint256 count = _count;
        if (count > leaderboard.length) {
            count = leaderboard.length;
        }

        address[] memory topPlayers = new address[](count);
        uint256[] memory topScores = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            address playerAddress = leaderboard[i];
            topPlayers[i] = playerAddress;
            topScores[i] = players[playerAddress].score;
        }

        return (topPlayers, topScores);
    }

    function getLeaderboard() external view returns (address[] memory) {
        return leaderboard;
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

        if (packetType == IbcPacketType.FAUCET) {
            (address caller, uint256 amount) = abi.decode(
                data,
                (address, uint256)
            );
            polyERC20.mint(caller, amount * 10 ** 18);
        } else if (packetType == IbcPacketType.BUY_NFT) {
            (address caller, NFTType nftType, uint256 tokenId) = abi.decode(
                data,
                (address, NFTType, uint256)
            );
            addToken(caller, tokenId, nftType);
            polyERC20.burn(nftPrice[nftType] * 10 ** 18);
            calculateUserPoint(caller);
            emit BuyNFTAckReceived(caller, tokenId, "NFT bought successfully");
        } else if (packetType == IbcPacketType.BUY_RANDOM_NFT) {
            (address caller, NFTType nftType, uint256 tokenId) = abi.decode(
                data,
                (address, NFTType, uint256)
            );
            addToken(caller, tokenId, nftType);
            polyERC20.burn(randomPriceBuyNFTAmount * 10 ** 18);
            calculateUserPoint(caller);
            emit BuyNFTAckReceived(
                caller,
                tokenId,
                "NFT bought random successfully"
            );
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
