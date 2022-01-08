
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILeaderboards
{
    enum ResetPeriod
    {
        Eternal,
        Yearly,
        Monthly,
        Weekly,
        Daily
    }
    function createLeaderboard() external returns(uint256);
    function getLeaderboard(uint256 leaderboardId, uint256 pageIndex) external view returns(string[] memory, uint256[] memory);
    function clearLeaderboard(uint256 leaderboardId) external;
    function getResetPeriod(uint256 leaderboardId) external view returns(ResetPeriod);
    function setResetPeriod(uint256 leaderboardId, ResetPeriod resetPeriod) external;
    function getCanScoresDecrease(uint256 leaderboardId) external view returns(bool);
    function setCanScoresDecrease(uint256 leaderboardId, bool canScoresDecrease) external;
    function getMaxSize(uint256 leaderboardId) external view returns(uint256);
    function setMaxSize(uint256 leaderboardId, uint256 maxSize) external;
    function getScore(uint256 leaderboardId, address player) external view returns(uint256);
    function getPositionForScore(uint256 leaderboardId, uint256 newScore) external view returns(uint256);
    function submitScore(uint256 leaderboardId, address player, uint256 newScore) external;
    function registerNickname(string memory nickname) external;
    function getNickname(address player) external view returns(string memory);
}