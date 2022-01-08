
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Leaderboards
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
    uint256 constant PAGE_LENGTH = 1000;

    struct Entry
    {
        bytes32 player;
        uint256 score;
        string nickname;
    }
    struct LeaderboardData
    {
        ResetPeriod resetPeriod;
        bool canScoresDecrease;
        uint256 maxSize;
        Entry[] entries;
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
        newBoard.maxSize = 1000000;
        leaderboards.push(newBoard); // Throws UnimplementedFeatureError: Copying of type struct Leaderboards.Entry memory[] memory to storage not yet supported.

        leaderboardOwners[id] = msg.sender;

        return id;
    }

    /**
     * 
     */
    function getLeaderboard(uint256 leaderboardId, uint256 pageIndex) public view 
        returns(string[PAGE_LENGTH] memory, uint256[PAGE_LENGTH] memory)
    {
        string[PAGE_LENGTH] memory nicknames;
        uint256[PAGE_LENGTH] memory scores;
        
        LeaderboardData memory board = leaderboards[leaderboardId];

        uint256 i = 0;
        uint256 k = pageIndex * PAGE_LENGTH;

        while (i < PAGE_LENGTH && k < board.entries.length)
        {
            nicknames[i] = board.entries[k].nickname;
            scores[i] = board.entries[k].score;
            i++;
            k++;
        }
        return (nicknames, scores);
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

        while (board.entries.length > _maxSize)
        {
            bytes32 lastPlayerId = board.entries[board.entries.length - 1].player;
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.entries.pop();
        }
    }

    /**
     * 
     */
    function getScore(uint256 leaderboardId, address player) public view returns(uint256)
    {
        bytes32 playerId = _getPlayerId(player);
        uint256 playerIndex = playerIndexOneBased[leaderboardId][playerId];
        if (playerIndex > 0)
        {
            playerIndex--;
            LeaderboardData memory board = leaderboards[leaderboardId];
            if (playerIndex < board.entries.length)
            {
                return board.entries[playerIndex].score;
            }
        }
        return 0;
    }

    /**
     * 
     */
    function getPositionForScore(uint256 leaderboardId, uint256 newScore) public view returns(uint256)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        for (uint256 i = 0; i < board.entries.length; i++)
        {
            if (newScore >= board.entries[i].score)
            {
                return i;
            }
        }
        return board.entries.length;
    }

    /**
     * 
     */
    function submitScore(uint256 leaderboardId, address player, uint256 newScore) public
    {
        _checkAuthority(leaderboardId);

        // TODO : Check reset period and call _clearLeaderboard()

        bytes32 playerId = _getPlayerId(player);
        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.maxSize == 0)
        {
            return;
        }

        // The leaderboard is empty, receiving its first score
        if (board.entries.length == 0)
        {
            playerIndexOneBased[leaderboardId][playerId] = 1;
            Entry memory entry = Entry(playerId, newScore, _getNickname(playerId));
            board.entries.push(entry);

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
            if (newScore == board.entries[playerIndex].score)
            {
                return;
            }
            // The new score is better than this player's old score. Search and insert
            if (newScore > board.entries[playerIndex].score)
            {
                while (playerIndex > 0)
                {
                    if (newScore < board.entries[playerIndex - 1].score)
                    {
                        break;
                    }
                    // Move other scores down by 1
                    bytes32 _pid = board.entries[playerIndex - 1].player;
                    playerIndexOneBased[leaderboardId][_pid]++;
                    board.entries[playerIndex] = board.entries[playerIndex - 1];

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
                while (playerIndex < board.entries.length - 1)
                {
                    uint256 i = playerIndex + 1;
                    if (newScore >= board.entries[i].score)
                    {
                        break;
                    }

                    // Move other scores up by 1
                    bytes32 _pid = board.entries[i].player;
                    playerIndexOneBased[leaderboardId][_pid]--;
                    board.entries[playerIndex] = board.entries[i];

                    playerIndex++;
                }
            }
        }
        // New player, with worst score of all
        else if (newScore < board.entries[board.entries.length - 1].score)
        {
            if (board.entries.length < board.maxSize)
            {
                Entry memory entry = Entry(playerId, newScore, _getNickname(playerId));
                board.entries.push(entry);
                playerIndexOneBased[leaderboardId][playerId] = board.entries.length;
            }
            return;
        }
        // New player, inserted in the middle somewhere
        else
        {
            playerIndex = 0;
            for ( ; playerIndex < board.entries.length; playerIndex++)
            {
                // Search for the index to insert at
                if (newScore >= board.entries[playerIndex].score)
                {
                    // Adjust the score at the bottom of the leaderboard
                    uint256 i = board.entries.length - 1;
                    bytes32 _pid = board.entries[i].player;
                    if (board.entries.length < board.maxSize)
                    {
                        playerIndexOneBased[leaderboardId][_pid]++;
                        board.entries.push(board.entries[i]);
                    }
                    else {
                        playerIndexOneBased[leaderboardId][_pid] = 0;
                    }
                    // Move other scores down by 1
                    while (i > playerIndex)
                    {
                        _pid = board.entries[i - 1].player;
                        playerIndexOneBased[leaderboardId][_pid]++;
                        board.entries[i] = board.entries[i - 1];
                        i--;
                    }
                    break;
                }
            }
        }
        // Emplace
        playerIndexOneBased[leaderboardId][playerId] = playerIndex + 1;
        board.entries[playerIndex].player = playerId;
        board.entries[playerIndex].score = newScore;
        board.entries[playerIndex].nickname = _getNickname(playerId);
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
        for (uint256 id = 1; id < nextLeaderboardId; id++)
        {
            uint256 playerIndex = playerIndexOneBased[id][playerId];
            if (playerIndex > 0)
            {
                LeaderboardData storage board = leaderboards[id];
                board.entries[playerIndex].nickname = _nickname;
            }
        }
    }

    /**
     * 
     */
    function getNickname(address player) public view returns(string memory)
    {
        bytes32 playerId = _getPlayerId(player);
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

        while (board.entries.length > 0)
        {
            bytes32 lastPlayerId = board.entries[board.entries.length - 1].player;
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.entries.pop();
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
}