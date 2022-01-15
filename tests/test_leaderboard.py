
from scripts.util import get_account, encode_function_data, update_proxy_contract
from brownie import Contract, Leaderboard
from scripts.deploy_contract import *
import time

def test_create():
    deploy_leaderboard()
    id = create_leaderboard()

    assert (id == 0)


def test_configure():
    id = create_leaderboard()

    assert (get_leaderboard_name(id) == "")
    set_leaderboard_name(id, "Loot Game")
    assert (get_leaderboard_name(id) == "Loot Game")

    assert (get_reset_period(id) == 0)
    set_reset_period(id, 2)
    assert (get_reset_period(id) == 2)

    assert (get_can_scores_decrease(id) == False)
    set_can_scores_decrease(id, True)
    assert (get_can_scores_decrease(id) == True)

    assert (get_max_size(id) == 100000)
    set_max_size(id, 2)
    assert (get_max_size(id) == 2)


def test_scores_1():
    id = create_leaderboard()

    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 0)

    position = get_position_for_score(id, 5)
    assert (position == 0)

    submit_score(id, get_account(), 7)
    nickname, score = get_entry(id, get_account())
    assert (score == 7)

    position = get_position_for_score(id, 5)
    assert (position == 1)

    position = get_position_for_score(id, 10)
    assert (position == 0)

    set_can_scores_decrease(id, False)
    submit_score(id, get_account(), 4)
    nickname, score = get_entry(id, get_account())
    assert (score == 7)

    set_can_scores_decrease(id, True)
    submit_score(id, get_account(), 4)
    nickname, score = get_entry(id, get_account())
    assert (score == 4)


def test_scores_2():
    # Create leaderboard with 5 players
    players = [
        '0x44d76e63F2c5c893c4aBdA08F3518F12aEBCc7EB',
        '0x5f75aedBe076d2Db28De18aDF4875DA6fc5eC358',
        '0xa7F172C8254288A3305D66eefA087f7Cf82a5fD4',
        '0x21aF8fcA9BA9090b7427985A9bbA564897AA276e',
        '0x0cC4d3c666913cBC28a95c463843705E7ec97027'
    ]
    id = create_leaderboard()

    submit_score(id, players[0], 1)
    submit_score(id, players[1], 2)
    submit_score(id, players[2], 3)
    submit_score(id, players[3], 4)
    submit_score(id, players[4], 5)

    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 5)

    nickname, score = get_entry(id, players[3])
    assert (score == 4)

    position = get_position_for_score(id, 3)
    assert (position == 2)

    # Move up, give player 1 a better score
    submit_score(id, players[1], 4)
    nicknames2, scores = get_leaderboard(id)
    assert (scores[0] == 5)
    assert (scores[1] == 4)
    assert (scores[2] == 4)
    assert (scores[3] == 3)
    assert (scores[4] == 1)
    assert (nicknames2[0] == nicknames[0])
    assert (nicknames2[1] == nicknames[3])
    assert (nicknames2[2] == nicknames[1])
    assert (nicknames2[3] == nicknames[2])
    assert (nicknames2[4] == nicknames[4])

    # Move down, give player 1 a lower score
    set_can_scores_decrease(id, True)
    submit_score(id, players[1], 0)
    nicknames2, scores = get_leaderboard(id)
    assert (scores[0] == 5)
    assert (scores[1] == 4)
    assert (scores[2] == 3)
    assert (scores[3] == 1)
    assert (scores[4] == 0)
    assert (nicknames2[0] == nicknames[0])
    assert (nicknames2[1] == nicknames[1])
    assert (nicknames2[2] == nicknames[2])
    assert (nicknames2[3] == nicknames[4])
    assert (nicknames2[4] == nicknames[3])

    # Decrease max entry count
    set_max_size(id, 2)
    nicknames2, scores = get_leaderboard(id)
    assert (len(scores) == 2)
    assert (scores[0] == 5)
    assert (scores[1] == 4)
    assert (nicknames2[0] == nicknames[0])
    assert (nicknames2[1] == nicknames[1])


def test_clear():
    id = create_leaderboard()

    submit_score(id, get_account(), 5)
    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 1)

    clear_leaderboard(id)
    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 0)


def test_nickname():
    id = create_leaderboard()
    submit_score(id, get_account(), 5)

    nickname = get_nickname()
    nicknames, scores = get_leaderboard(id)
    assert (not nickname.startswith("standardcombo"))
    assert (not nicknames[0].startswith("standardcombo"))

    register_nickname(get_account(), "standardcombo")
    nickname = get_nickname()
    nicknames, scores = get_leaderboard(id)
    assert (nickname.startswith("standardcombo"))
    assert (nicknames[0].startswith("standardcombo"))

    register_nickname(get_account(), "alice bob charli")
    nickname = get_nickname()
    assert (nickname.startswith("alice bob charli"))

    register_nickname(get_account(), "1234567890123456789012345678901234567890")
    nickname = get_nickname()
    assert (nickname.startswith("1234567890123456"))


def test_reset_timestamp():
    id = create_leaderboard()

    currentTimestamp = int( time.time() )

    ONE_DAY = 60 * 60 * 24
    ONE_WEEK = ONE_DAY * 7
    ONE_MONTH = ONE_DAY * 30
    ONE_YEAR = ONE_DAY * 365

    seconds = get_reset_timestamp(id)
    assert (seconds == 0)

    set_reset_period(id, 4)

    seconds = get_reset_timestamp(id)
    assert (get_reset_period(id) == 4)
    assert (seconds == ONE_DAY)
    
    submit_score(id, get_account(), 5)
    seconds = get_reset_timestamp(id)
    assert (seconds >= currentTimestamp + ONE_DAY and seconds <= currentTimestamp + ONE_DAY + 2)

    set_reset_period(id, 3)
    seconds = get_reset_timestamp(id)
    assert (seconds >= currentTimestamp + ONE_WEEK and seconds <= currentTimestamp + ONE_WEEK + 2)

    set_reset_period(id, 2)
    seconds = get_reset_timestamp(id)
    assert (seconds >= currentTimestamp + ONE_MONTH and seconds <= currentTimestamp + ONE_MONTH + 2)

    set_reset_period(id, 1)
    seconds = get_reset_timestamp(id)
    assert (seconds >= currentTimestamp + ONE_YEAR and seconds <= currentTimestamp + ONE_YEAR + 2)

