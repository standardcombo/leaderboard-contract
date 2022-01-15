
from brownie import Leaderboard, config, network
from scripts.util import get_account


def deploy_leaderboard():
    print("Deploying Leaderboard")
    account = get_account()

    networkConfig = config["networks"][network.show_active()]

    Leaderboard.deploy(
        {"from": account},
        publish_source = False # networkConfig["verify_source_code"]
    )
    

def create_leaderboard():
    print("Create Leaderboard")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.createLeaderboard({"from": account})
    tx.wait(1)
    leaderboardId = tx.return_value
    print("Created with id " + str(leaderboardId))
    return leaderboardId


def get_leaderboard(_leaderboard_id):
    print("Get Leaderboard")
    account = get_account()
    contract = Leaderboard[-1]
    nicknames, scores = contract.getLeaderboard(_leaderboard_id, {"from": account})
    for i in range(len(nicknames)):
        print(nicknames[i], scores[i])
    return nicknames, scores


def clear_leaderboard(_leaderboard_id):
    print("Clear Leaderboard")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.clearLeaderboard(_leaderboard_id, {"from": account})
    tx.wait(1)


def get_leaderboard_name(_leaderboard_id):
    print("Get Leaderboard Name")
    account = get_account()
    contract = Leaderboard[-1]
    leaderboardName = contract.getName(_leaderboard_id, {"from": account})
    print("Current name = " + str(leaderboardName))
    return leaderboardName


def set_leaderboard_name(_leaderboard_id, new_name):
    print("Set Leaderboard Name")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.setName(_leaderboard_id, new_name, {"from": account})
    tx.wait(1)


def get_reset_period(_leaderboard_id):
    print("Get Reset Period")
    account = get_account()
    contract = Leaderboard[-1]
    resetPeriod = contract.getResetPeriod(_leaderboard_id, {"from": account})
    print("Current reset period = " + str(resetPeriod))
    return resetPeriod


def set_reset_period(_leaderboard_id, reset_period):
    print("Set Reset Period")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.setResetPeriod(_leaderboard_id, reset_period, {"from": account})
    tx.wait(1)


def get_can_scores_decrease(_leaderboard_id):
    print("Get Can Scores Decrease")
    account = get_account()
    contract = Leaderboard[-1]
    canDecrease = contract.getCanScoresDecrease(_leaderboard_id, {"from": account})
    if canDecrease:
        print("Scores can decrease for this leaderboard.")
    else:
        print("Scores cannot be decreased on this leaderboard.")
    return canDecrease


def set_can_scores_decrease(_leaderboard_id, can_decrease):
    print("Set Can Scores Decrease")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.setCanScoresDecrease(_leaderboard_id, can_decrease, {"from": account})
    tx.wait(1)


def get_max_size(_leaderboard_id):
    print("Get Max Size")
    account = get_account()
    contract = Leaderboard[-1]
    size = contract.getMaxSize(_leaderboard_id, {"from": account})
    print("Max leaderboard size = " + str(size))
    return size


def set_max_size(_leaderboard_id, max_size):
    print("Set Max Size")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.setMaxSize(_leaderboard_id, max_size, {"from": account})
    tx.wait(1)


def get_entry(_leaderboard_id, player_address):
    print("Get Entry")
    contract = Leaderboard[-1]
    nickname, score = contract.getEntry(_leaderboard_id, {"from": player_address})
    print(nickname, score)
    return nickname, score


def get_position_for_score(_leaderboard_id, new_score):
    print("Get Position For Score")
    account = get_account()
    contract = Leaderboard[-1]
    position = contract.getPositionForScore(_leaderboard_id, new_score, {"from": account})
    print("Score " + str(new_score) + " fits into position " + str(position))
    return position


def submit_score(_leaderboard_id, player_address, new_score):
    print("Submit Score")
    account = get_account()
    contract = Leaderboard[-1]
    tx = contract.submitScore(_leaderboard_id, player_address, new_score, {"from": account})
    tx.wait(1)


def get_reset_timestamp(_leaderboard_id):
    print("Get Reset Timestamp")
    account = get_account()
    contract = Leaderboard[-1]
    seconds = contract.getResetTimestamp(_leaderboard_id, {"from": account})
    print("Will reset at " + str(seconds) + " seconds from unix epoch.")
    return seconds


def register_nickname(player_address, newNickname):
    print("Register Nickname")
    contract = Leaderboard[-1]
    tx = contract.registerNickname(newNickname, {"from": player_address})
    tx.wait(1)


def get_nickname():
    print("Get Nickname")
    account = get_account()
    contract = Leaderboard[-1]
    nickname = contract.getNickname({"from": account})
    print(nickname)
    return nickname


def main():
    deploy_leaderboard()
    _id = create_leaderboard()
    register_nickname(get_account(), "standardcombo")
    submit_score(_id, get_account(), 55)
    get_leaderboard(_id)

