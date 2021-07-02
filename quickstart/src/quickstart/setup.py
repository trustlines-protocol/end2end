import os
import shutil

from quickstart.utils import config_file_getter

README_PATH = "readme.txt"
README_TEXT = "\n".join(
    [
        "# Readme",
        "",
        "You can check which services are running with `docker-compose ps`.",
        "You can use `docker-compose down` to shut the services down or `docker-compose up` to start them. "
        "You can also stop individual services for example `docker-compose stop relay`.",
        "For more information see the docker-compose documentation via `docker-compose --help` "
        "or online at https://docs.docker.com/compose/. "
        "You can also check the docker documentation via `docker --help` or online at "
        "https://docs.docker.com/engine/reference/commandline/docker/",
    ]
)


def setup(chain_name, base_dir):
    create_docker_readme(base_dir)

    copy_config_files(chain_name, base_dir)
    copy_starting_script(base_dir)


def create_docker_readme(base_dir):
    if not os.path.isfile(os.path.join(base_dir, README_PATH)):
        with open(os.path.join(base_dir, README_PATH), "x") as f:
            f.write(README_TEXT)


def copy_config_files(chain_name, base_dir):
    shutil.copy(config_file_getter(chain_name, "docker-compose.yaml")(), base_dir)
    shutil.copy(config_file_getter(chain_name, "addresses.json")(), base_dir)
    shutil.copy(config_file_getter("shared", "config.toml")(), base_dir)


def copy_starting_script(base_dir):
    shutil.copy(config_file_getter("shared", "run-e2e.sh")(), base_dir)
