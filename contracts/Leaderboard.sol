
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Leaderboard
{
    enum ResetPeriod
    {
        Eternal,
        Yearly,
        Monthly,
        Weekly,
        Daily
    }

    uint8 constant MAX_NICKNAME_LENGTH = 16;

    struct LeaderboardData
    {
        ResetPeriod resetPeriod;
        bool canScoresDecrease;
        uint256 maxSize;
        bytes32[] players;
        uint256[] scores;
        string[] nicknames;
        uint256 firstTimestamp;
    }

    LeaderboardData[] leaderboards;
    uint256 nextLeaderboardId;

    mapping(uint256 => address) leaderboardOwners;
    mapping(bytes32 => string) playerNicknames;

    // A value of 0 means the player does not have a score on that leaderboard
    mapping(uint256 => mapping(bytes32 => uint256)) playerIndexOneBased;

    /**
     * 
     */
    function createLeaderboard() public returns(uint256)
    {
        uint256 id = nextLeaderboardId;
        nextLeaderboardId++;

        LeaderboardData memory newBoard;
        newBoard.maxSize = 100000;
        leaderboards.push(newBoard);

        leaderboardOwners[id] = msg.sender;

        return id;
    }

    /**
     * 
     */
    function getLeaderboard(uint256 leaderboardId) public view returns(string[] memory, uint256[] memory)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return (board.nicknames, board.scores);
    }

    /**
     * 
     */
    function clearLeaderboard(uint256 leaderboardId) public
    {
        _checkAuthority(leaderboardId);
        _clearLeaderboard(leaderboardId);
    }

    /**
     * 
     */
    function getResetPeriod(uint256 leaderboardId) public view returns(ResetPeriod)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.resetPeriod;
    }

    /**
     * 
     */
    function setResetPeriod(uint256 leaderboardId, ResetPeriod _resetPeriod) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.resetPeriod = _resetPeriod;
    }

    /**
     * 
     */
    function getCanScoresDecrease(uint256 leaderboardId) public view returns(bool)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.canScoresDecrease;
    }

    /**
     * 
     */
    function setCanScoresDecrease(uint256 leaderboardId, bool _canScoresDecrease) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.canScoresDecrease = _canScoresDecrease;
    }

    /**
     * 
     */
    function getMaxSize(uint256 leaderboardId) public view returns(uint256)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.maxSize;
    }

    /**
     * 
     */
    function setMaxSize(uint256 leaderboardId, uint256 _maxSize) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.maxSize = _maxSize;

        while (board.scores.length > _maxSize)
        {
            bytes32 lastPlayerId = board.players[board.scores.length - 1];
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.players.pop();
            board.scores.pop();
            board.nicknames.pop();
        }
    }

    /**
     * 
     */
    function getEntry(uint256 leaderboardId, address player) public view returns(string memory, uint256)
    {
        bytes32 playerId = _getPlayerId(player);
        uint256 playerIndex = playerIndexOneBased[leaderboardId][playerId];
        if (playerIndex > 0)
        {
            playerIndex--;
            LeaderboardData memory board = leaderboards[leaderboardId];
            if (playerIndex < board.scores.length)
            {
                return (board.nicknames[playerIndex], board.scores[playerIndex]);
            }
        }
        return ("", 0);
    }

    /**
     * 
     */
    function getPositionForScore(uint256 leaderboardId, uint256 newScore) public view returns(uint256)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        for (uint256 i = 0; i < board.scores.length; i++)
        {
            if (newScore <= board.scores[i])
            {
                return i;
            }
        }
        return board.scores.length;
    }

    /**
     * 
     */
    function submitScore(uint256 leaderboardId, address player, uint256 newScore) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.maxSize == 0)
        {
            return;
        }

        bytes32 playerId = _getPlayerId(player);
        
        // Clear leaderboard if the period has reset
        if (_checkResetPeriod(leaderboardId))
        {
            _clearLeaderboard(leaderboardId);
        }

        // The leaderboard is empty, receiving its first score
        if (board.scores.length == 0)
        {
            board.firstTimestamp = block.timestamp;

            playerIndexOneBased[leaderboardId][playerId] = 1;
            board.players.push(playerId);
            board.scores.push(newScore);
            board.nicknames.push(_getNickname(playerId));

            return;
        }

        // Check if this player already has a score on this leaderboard
        uint256 playerIndex = playerIndexOneBased[leaderboardId][playerId];
        bool hasPreviousScore = false;
        if (playerIndex > 0 && playerIndex < board.maxSize)
        {
            hasPreviousScore = true;
            playerIndex--;
        }

        // Player that is already on this leaderboard
        if (hasPreviousScore)
        {
            // Same score. No change
            if (newScore == board.scores[playerIndex])
            {
                return;
            }
            // The new score is better than this player's old score. Search and insert
            if (newScore > board.scores[playerIndex])
            {
                while (playerIndex > 0)
                {
                    if (newScore < board.scores[playerIndex - 1])
                    {
                        break;
                    }
                    // Move other scores down by 1
                    playerIndexOneBased[leaderboardId][board.players[playerIndex - 1]]++;
                    board.players[playerIndex] = board.players[playerIndex - 1];
                    board.scores[playerIndex] = board.scores[playerIndex - 1];
                    board.nicknames[playerIndex] = board.nicknames[playerIndex - 1];

                    playerIndex--;
                }
            }
            else // The new score is lower than the previous score
            {
                // However, the leaderboard may be configured to not allow saving worse scores
                if ( !board.canScoresDecrease )
                {
                    return;
                }
                // Search
                while (playerIndex < board.scores.length - 1)
                {
                    uint256 i = playerIndex + 1;
                    if (newScore >= board.scores[i])
                    {
                        break;
                    }

                    // Move other scores up by 1
                    playerIndexOneBased[leaderboardId][board.players[i]]--;
                    board.players[playerIndex] = board.players[i];
                    board.scores[playerIndex] = board.scores[i];
                    board.nicknames[playerIndex] = board.nicknames[i];

                    playerIndex++;
                }
            }
        }
        // New player, with worst score of all
        else if (newScore < board.scores[board.scores.length - 1])
        {
            if (board.scores.length < board.maxSize)
            {
                board.players.push(playerId);
                board.scores.push(newScore);
                board.nicknames.push(_getNickname(playerId));
                playerIndexOneBased[leaderboardId][playerId] = board.scores.length;
            }
            return;
        }
        // New player, inserted in the middle somewhere
        else
        {
            playerIndex = 0;
            for ( ; playerIndex < board.scores.length; playerIndex++)
            {
                // Search for the index to insert at
                if (newScore >= board.scores[playerIndex])
                {
                    // Adjust the score at the bottom of the leaderboard
                    uint256 i = board.scores.length - 1;
                    if (board.scores.length < board.maxSize)
                    {
                        playerIndexOneBased[leaderboardId][board.players[i]]++;
                        board.players.push(board.players[i]);
                        board.scores.push(board.scores[i]);
                        board.nicknames.push(board.nicknames[i]);
                    }
                    else {
                        playerIndexOneBased[leaderboardId][board.players[i]] = 0;
                    }
                    // Move other scores down by 1
                    while (i > playerIndex)
                    {
                        playerIndexOneBased[leaderboardId][board.players[i - 1]]++;
                        board.players[i] = board.players[i - 1];
                        board.scores[i] = board.scores[i - 1];
                        board.nicknames[i] = board.nicknames[i - 1];
                        i--;
                    }
                    break;
                }
            }
        }
        // Emplace
        playerIndexOneBased[leaderboardId][playerId] = playerIndex + 1;
        board.players[playerIndex] = playerId;
        board.scores[playerIndex] = newScore;
        board.nicknames[playerIndex] = _getNickname(playerId);
    }

    /**
     * 
     */
    function getResetSecondsRemaining(uint256 leaderboardId) public view returns(int256)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.resetPeriod == ResetPeriod.Eternal)
        {
            return 0;
        }
        uint256 currentTime = block.timestamp;
        uint256 expireTime = board.firstTimestamp;
        
        if (board.resetPeriod == ResetPeriod.Daily)
        {
            expireTime += 60 * 60 * 24; // 24 hours
        }
        else if (board.resetPeriod == ResetPeriod.Weekly)
        {
            expireTime += 60 * 60 * 24 * 7; // 7 days
        }
        else if (board.resetPeriod == ResetPeriod.Monthly)
        {
            expireTime += 60 * 60 * 24 * 30; // 30 days
        }
        else if (board.resetPeriod == ResetPeriod.Yearly)
        {
            expireTime += 60 * 60 * 24 * 365; // 1 year
        }
        if (currentTime > expireTime)
        {
            return -int256(currentTime - expireTime);
        }
        return int256(expireTime - currentTime);
    }

    /**
     * 
     */
    function registerNickname(string memory _nickname) public
    {
        // Limit the size
        bytes memory strBytes = bytes(_nickname);
        if (strBytes.length > MAX_NICKNAME_LENGTH)
        {
            bytes memory result = new bytes(MAX_NICKNAME_LENGTH);
            for(uint i = 0; i < MAX_NICKNAME_LENGTH; i++) {
                result[i] = strBytes[i];
            }
            _nickname = string(result);
        }

        // Save nickname
        bytes32 playerId = _getPlayerId(msg.sender);
        _nickname = string(abi.encodePacked(_nickname, " ", _getPlayerIdAbbreviation(playerId)));
        playerNicknames[playerId] = _nickname;

        // Update existing entries for this player across all leaderboards
        for (uint256 id = 0; id < nextLeaderboardId; id++)
        {
            uint256 playerIndex = playerIndexOneBased[id][playerId];
            if (playerIndex > 0)
            {
                playerIndex--;
                LeaderboardData storage board = leaderboards[id];
                board.nicknames[playerIndex] = _nickname;
            }
        }
    }

    /**
     * 
     */
    function getNickname() public view returns(string memory)
    {
        bytes32 playerId = _getPlayerId(msg.sender);
        return _getNickname(playerId);
    }

    function _getNickname(bytes32 playerId) internal view returns(string memory)
    {
        if (bytes(playerNicknames[playerId]).length > 0)
        {
            return playerNicknames[playerId];
        }
        return _getPlayerIdAbbreviation(playerId);
    }

    function _getPlayerIdAbbreviation(bytes32 playerId) internal pure returns(string memory)
    {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(6);
        str[0] = "0";
        str[1] = "x";
        uint n = 2;
        for (uint i = 0; n < str.length; i++) {
            str[n] = alphabet[uint(uint8(playerId[i] >> 4))];
            str[n+1] = alphabet[uint(uint8(playerId[i] & 0x0f))];
            n += 2;
        }
        return string(str);
    }

    function _clearLeaderboard(uint256 leaderboardId) internal
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        while (board.scores.length > 0)
        {
            bytes32 lastPlayerId = board.players[board.scores.length - 1];
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.players.pop();
            board.scores.pop();
            board.nicknames.pop();
        }
    }

    function _checkAuthority(uint256 leaderboardId) internal view
    {
        require(leaderboardOwners[leaderboardId] == msg.sender, "No permission to change leaderboard.");
    }

    function _getPlayerId(address player) internal pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(player));
    }

    function _checkResetPeriod(uint256 leaderboardId) internal view returns(bool)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.resetPeriod == ResetPeriod.Eternal)
        {
            return false;
        }
        return getResetSecondsRemaining(leaderboardId) == 0;
    }
}