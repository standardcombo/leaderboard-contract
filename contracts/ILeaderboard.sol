
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILeaderboard
{
    // How frequently the leaderboard auto-clears
    enum ResetPeriod
    {
        Eternal,    // 0
        Yearly,     // 1
        Monthly,    // 2
        Weekly,     // 3
        Daily       // 4
    }

    // Returns the ID of a new leaderboard. Use this ID in future calls. Address that calls this is set as the owner.
    function createLeaderboard() external returns(uint256);

    // Returns two arrays of equal size, with player nicknames and scores.
    function getLeaderboard(uint256 leaderboardId) external view returns(string[] memory, uint256[] memory);

    // Clears a leaderboard. Restricted to caller of createLeaderboard().
    function clearLeaderboard(uint256 leaderboardId) external;

    // Returns the name of the leaderboard, if any.
    function getName(uint256 leaderboardId) external view returns(string memory);

    // Set a new name for the leaderboard. Restricted to caller of createLeaderboard().
    function setName(uint256 leaderboardId, string memory name) external;

    // Returns the frequency at which the leaderboard auto-clears. Default is 'Eternal'.
    function getResetPeriod(uint256 leaderboardId) external view returns(ResetPeriod);

    // Set the frequency at which the leaderboard auto-clears. Restricted to caller of createLeaderboard().
    function setResetPeriod(uint256 leaderboardId, ResetPeriod resetPeriod) external;

    // Returns the leaderboard's 'canScoresDecrease' property.
    function getCanScoresDecrease(uint256 leaderboardId) external view returns(bool);

    // If set to True, then a new player's score replaces their previous score, even if it's a worse score. Default is False. Restricted to caller of createLeaderboard().
    function setCanScoresDecrease(uint256 leaderboardId, bool canScoresDecrease) external;

    // Returns the maximum number of entries for a given leaderboard.
    function getMaxSize(uint256 leaderboardId) external view returns(uint256);

    // Sets the maximum number of entries on a leaderboard. Restricted to caller of createLeaderboard().
    function setMaxSize(uint256 leaderboardId, uint256 maxSize) external;

    // Returns the leaderboard entry for the caller (nickname, score). Local only: The contract uses `msg.sender` as the player to lookup.
    function getEntry(uint256 leaderboardId) external view returns(string memory, uint256);

    // Given an arbitrary score value, estimates what position on the leaderboard it would appear, if submitted.
    function getPositionForScore(uint256 leaderboardId, uint256 newScore) external view returns(uint256);

    // Submits a new score for a player. Restricted to caller of createLeaderboard().
    function submitScore(uint256 leaderboardId, address player, uint256 newScore) external;

    // Returns a list of leaderboard IDs in which the local player has any scores.
    function getLeaderboardsForPlayer() external view returns(uint256[] memory);

    // Returns the timestamp when the leaderboard will auto-clear, in seconds since unix epoch. In case of 'Eternal' returns zero.
    function getResetTimestamp(uint256 leaderboardId) external view returns(uint256);

    // Allows a player to register their nickname with all leaderboards created with the contract. Player addresses are anonymized.
    function registerNickname(string memory nickname) external;

    // Returns the nickname for the caller. Local only: The contract uses `msg.sender` to lookup the nickname.
    function getNickname() external view returns(string memory);
}