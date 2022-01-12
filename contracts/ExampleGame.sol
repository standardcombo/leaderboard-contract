
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILeaderboard.sol";

contract ExampleGame
{
    address leaderboardAddress;
    uint256 leaderboardId;

    mapping(address => uint256) private points;

    function setup(address _leaderboardAddress) public
    {
        leaderboardAddress = _leaderboardAddress;
        leaderboardId = ILeaderboard(leaderboardAddress).createLeaderboard();
    }

    function earnPoints() public
    {
        address player = msg.sender;
        points[player]++;

        ILeaderboard(leaderboardAddress).submitScore(leaderboardId, player, points[player]);
    }

    function getLeaderboard() public view returns(string[] memory, uint256[] memory)
    {
        return ILeaderboard(leaderboardAddress).getLeaderboard(leaderboardId);
    }
}