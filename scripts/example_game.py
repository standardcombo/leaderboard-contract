
from brownie import ExampleGame, Leaderboard, config, network
from brownie.network import contract
from scripts.util import get_account
from scripts.deploy_contract import *
import time


def deploy_game():
    print("Deploying Example Game")
    account = get_account()
    ExampleGame.deploy({"from": account})
    

def setup_leaderboard():
    print("Setup Leaderboard")
    networkConfig = config["networks"][network.show_active()]
    #if (networkConfig["leaderboard"]):
    #    leaderboardAddress = networkConfig["leaderboard"]
    #else:
    #    deploy_leaderboard()
    #    leaderboardAddress = Leaderboard[-1]
    leaderboardAddress = networkConfig["leaderboard"]

    account = get_account()
    contract = ExampleGame[-1]
    tx = contract.setup(leaderboardAddress, {"from": account})
    tx.wait(1)

        
def earn_points():
    print("Earning Points")
    account = get_account()
    contract = ExampleGame[-1]
    for i in range(5):
        tx = contract.earnPoints({"from": account})
        tx.wait(1)
        time.sleep(1)


def register_nickname():
    print("Registering Nickname")
    account = get_account()
    tx = Leaderboard[-1].registerNickname("standardcombo", {"from": account})
    tx.wait(1)


def get_leaderboard():
    print("Getting Leaderboard")
    account = get_account()
    contract = ExampleGame[-1]
    nicknames, scores = contract.getLeaderboard({"from": account})
    for i in range(len(nicknames)):
        print(nicknames[i], scores[i])


def main():
    deploy_game()
    setup_leaderboard()
    #earn_points()
    #register_nickname()
    #get_leaderboard()