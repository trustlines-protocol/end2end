import os

CONFIG_DIR = "config"
ENODE_DIR = "enode"
DATABASE_DIR = "databases"
KEY_DIR = os.path.join(CONFIG_DIR, "keys")

KEYSTORE_FILE_NAME = "account.json"
LEGACY_KEYSTORE_FILE_NAME_PATTERN = "UTC-*"
PASSWORD_FILE_NAME = "pass.pwd"

PASSWORD_FILE_PATH = os.path.join(CONFIG_DIR, PASSWORD_FILE_NAME)
ADDRESS_FILE_PATH = os.path.join(CONFIG_DIR, "address")
AUTHOR_ADDRESS_FILE_PATH = os.path.join(CONFIG_DIR, "author-address")
