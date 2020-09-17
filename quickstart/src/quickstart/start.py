import os
import subprocess
import typing

import click

from quickstart.node_account import get_account_address


# Ignore typing because it seems not to handle `subprocess.run` **kwargs properly
@typing.no_type_check
def start(*, base_dir, host_base_dir, chain_name,) -> None:

    env_variables = {
        "COMPOSE_PROJECT_NAME": chain_name,
        "ADDRESS_ARG": f"--address {get_account_address(base_dir)}",
        "UNLOCK_ADDRESS": get_account_address(base_dir),
        "PGHOST": "db",
        "PGUSER": "trustlines_test",
        "POSTGRES_USER": "trustlines_test",
        "PGDATABASE": "trustlines_test",
        "PGPASSWORD": "test123",
        "POSTGRES_PASSWORD": "test123",
    }

    with open(os.path.join(base_dir, ".env"), mode="w") as env_file:
        env_file.writelines(
            f"{key}={value}\n" for (key, value) in env_variables.items()
        )

    runtime_env_variables = {**os.environ, **env_variables}

    if host_base_dir is not None:
        runtime_env_variables["HOST_BASE_DIR"] = host_base_dir

    run_kwargs = {
        "env": runtime_env_variables,
        "stdout": subprocess.PIPE,
        "stderr": subprocess.PIPE,
        "universal_newlines": True,
    }

    try:
        subprocess.run(
            os.path.join(base_dir, "run-e2e.sh"), check=True, **run_kwargs,
        )
    except subprocess.CalledProcessError as called_process_error:
        raise click.ClickException(
            "\n".join(
                (
                    f"Command {called_process_error.cmd} failed with exit code "
                    f"{called_process_error.returncode}.",
                    "Captured stderr:",
                    f"{called_process_error.stderr}",
                )
            )
        )
