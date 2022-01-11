
from scripts.util import get_account, encode_function_data, update_proxy_contract
from brownie import Contract, Leaderboard
from scripts.deploy_contract import *

def test_create():
    deploy()
    id = create_leaderboard()

    assert (id == 0)


def test_configure():
    id = create_leaderboard()

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
    assert (position == 0)

    position = get_position_for_score(id, 10)
    assert (position == 1)

    set_can_scores_decrease(id, False)
    submit_score(id, get_account(), 4)
    nickname, score = get_entry(id, get_account())
    assert (score == 7)

    set_can_scores_decrease(id, True)
    submit_score(id, get_account(), 4)
    nickname, score = get_entry(id, get_account())
    assert (score == 4)


def test_scores_2():
    # TODO
    # Add scores for multiple people
    # Add above, below, equal value, etc
    pass


def test_clear():
    id = create_leaderboard()

    submit_score(id, get_account(), 5)
    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 1)

    clear_leaderboard(id)
    nicknames, scores = get_leaderboard(id)
    assert (len(nicknames) == 0)


def test_nickname():
    nickname = get_nickname()
    assert (not nickname.startswith("standardcombo"))

    register_nickname(get_account(), "standardcombo")
    nickname = get_nickname()
    assert (nickname.startswith("standardcombo"))

    register_nickname(get_account(), "alice bob charli")
    nickname = get_nickname()
    assert (nickname.startswith("alice bob charli"))

    register_nickname(get_account(), "1234567890123456789012345678901234567890")
    nickname = get_nickname()
    assert (nickname.startswith("1234567890123456"))


def test_size_limit():
    # TODO
    pass


def test_seconds_remaining():
    # TODO
    pass


