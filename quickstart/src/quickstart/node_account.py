import json
import os
from textwrap import fill

import click
from eth_account import Account

from quickstart.constants import (
    ADDRESS_FILE_PATH,
    CONFIG_DIR,
    DATABASE_DIR,
    ENODE_DIR,
    KEY_DIR,
    KEYSTORE_FILE_NAME,
    PASSWORD_FILE_PATH,
)
from quickstart.utils import (
    TrustlinesFiles,
    ensure_clean_setup,
    get_keystore_path,
    read_decryption_password,
    read_encryption_password,
    read_private_key,
)


def setup_interactively(base_dir, chain_dir) -> None:

    if is_account_prepared(base_dir):
        click.echo("An account has already been set up.")
        return

    make_required_dirs(base_dir, chain_dir)

    ensure_clean_setup(base_dir, chain_dir)

    choice = click.prompt(
        fill(
            "The account needs a private key. Do you want to import an existing JSON "
            "keystore (1), enter a raw private key (2), or generate a new key (3) ?"
        )
        + "\n",
        type=click.Choice(("1", "2", "3")),
        show_choices=False,
    )

    if choice == "1":
        import_keystore_file(base_dir, chain_dir)
    elif choice == "2":
        import_private_key(base_dir, chain_dir)
    elif choice == "3":
        generate_new_account(base_dir, chain_dir)
    else:
        assert False, "unreachable"


def make_required_dirs(base_dir, chain_dir):
    """Make the directory with which the quickstart could interact before openethereum makes them
    to have write access"""
    os.makedirs(os.path.join(base_dir, CONFIG_DIR), exist_ok=True)
    os.makedirs(os.path.join(base_dir, ENODE_DIR), exist_ok=True)
    os.makedirs(os.path.join(base_dir, DATABASE_DIR), exist_ok=True)
    os.makedirs(os.path.join(base_dir, KEY_DIR, chain_dir), exist_ok=True)


def import_keystore_file(base_dir, chain_dir) -> None:
    click.echo("Starting to import an existing keystore...")
    keystore_path = get_keystore_path()

    with open(keystore_path, "rb") as keystore_file:
        keyfile_dict = json.load(keystore_file)

    account, password = read_decryption_password(keyfile_dict)
    trustlines_files = TrustlinesFiles(
        os.path.join(base_dir, PASSWORD_FILE_PATH),
        os.path.join(base_dir, ADDRESS_FILE_PATH),
        os.path.join(base_dir, KEY_DIR, chain_dir, KEYSTORE_FILE_NAME),
    )
    trustlines_files.store(account, password)


def import_private_key(base_dir, chain_dir) -> None:
    click.echo("Starting to import an existing raw private key...")
    private_key = read_private_key()
    account = Account.from_key(private_key)
    password = read_encryption_password()
    trustlines_files = TrustlinesFiles(
        os.path.join(base_dir, PASSWORD_FILE_PATH),
        os.path.join(base_dir, ADDRESS_FILE_PATH),
        os.path.join(base_dir, KEY_DIR, chain_dir, KEYSTORE_FILE_NAME),
    )
    trustlines_files.store(account, password)


def generate_new_account(base_dir, chain_dir) -> None:
    click.echo("Starting to generate a new private key...")
    account = Account.create()
    password = read_encryption_password()
    trustlines_files = TrustlinesFiles(
        os.path.join(base_dir, PASSWORD_FILE_PATH),
        os.path.join(base_dir, ADDRESS_FILE_PATH),
        os.path.join(base_dir, KEY_DIR, chain_dir, KEYSTORE_FILE_NAME),
    )
    trustlines_files.store(account, password)


def get_account_address(base_dir) -> str:
    if not is_account_prepared(base_dir):
        raise ValueError("Account is not prepared! Can not read its address.")

    with open(os.path.join(base_dir, ADDRESS_FILE_PATH), "r") as address_file:
        return address_file.read()


def is_account_prepared(base_dir) -> bool:
    return os.path.isfile(os.path.join(base_dir, ADDRESS_FILE_PATH))
