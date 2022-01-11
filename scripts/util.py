
from brownie import network, config, accounts
import eth_utils

def is_development():
    return network.show_active() in [
        "development",
        "ganache-local",
    ]

def is_mainnet():
    return network.show_active() == "mainnet"

def is_mainnet_fork():
    return network.show_active() == "mainnet-fork"

def get_account():
    if is_development() or is_mainnet_fork():
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])

def opensea_url():
    if is_mainnet():
        return "https://opensea.io/assets/{}/{}"
    return "https://testnets.opensea.io/assets/{}/{}"

# Used when forwarding a function call + parameters to a contract. 
# E.g.: encode_function_data(func=obj.function, 1, address, "foo")
def encode_function_data(func=None, *args):
    if len(args) == 0 or not func:
        return eth_utils.to_bytes(hexstr="0x")
    return func.encode_input(*args)

# Transparent proxy pattern. A contract implementation is upgraded to a new version
def update_proxy_contract(
    account, 
    proxy_contract, 
    new_implementation_address, 
    proxy_admin=None, 
    initializer=None, 
    *args):
    tx = None
    if proxy_admin:
        if initializer:
            encoded_init = encode_function_data(initializer, *args)
            tx = proxy_admin.upgradeAndCall(
                proxy_contract.address,
                new_implementation_address,
                encoded_init,
                {"from": account}
            )
        else:
            tx = proxy_admin.upgrade(
                proxy_contract.address,
                new_implementation_address,
                {"from": account}
            )
    else:
        if initializer:
            encoded_init = encode_function_data(initializer, *args)
            tx = proxy_contract.upgradeToAndCall(
                new_implementation_address,
                encoded_init,
                {"from": account}
            )
        else:
            tx = proxy_admin.upgradeTo(
                new_implementation_address,
                {"from": account}
            )
    return tx