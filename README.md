# leaderboard-contract

The idea behind this project is that nobody in the multiverse should ever have to create or deploy a leaderboard-- just call this one with minimal integration.

The Leaderboard contract is designed as a multi-tenant system for on-chain composition. No fees or tokens, only gas. This leaderboard is intended to be deployed only once per network, thereafter called by any number of games/applications who desire the service.

Features:
- Multi-tenant: A single contract for all apps.
- Reset periods: Daily, Weekly, Monthly, Yearly or Eternal.
- Nicknames controlled by the individual players.
- Option to ignore or accept new scores, when they are worse than previous ones.
- Option to limit a leaderboard's size.
- Function that predicts the position of a hypothetical new score, for certain UI cases.
- Leaderboard data about the local player, for certain UI cases.

Usage:
1. Call createContract() to receive a new leaderboard ID.
2. Call submitScore() to save player scores.
3. Call getLeaderboard() to receive a sorted table of player nicknames and scores.

See the ExampleGame.sol for an example of on-chain usage.
See function headers for details about parameters and return values.
