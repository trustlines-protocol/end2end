import click

from quickstart import setup, node_account, utils
from quickstart.start import start

DEFAULT_CONFIGS = ["laika", "tlbc"]
LAIKA, TLBC = DEFAULT_CONFIGS


def docker_compose_file_getter(config_name):
    return utils.config_file_getter(config_name, "docker-compose.yaml")


class DefaultPathType(click.Path):
    def __init__(self, default_path_lookups, *args, **kwargs):
        """
        Like the click path type, but additionally accepts a mapping for predefined paths
        :param default_path_lookups: mapping from template name to lookup function
        :param args: args for click.Path
        :param kwargs: kwargs for click.Path
        """
        super().__init__(*args, **kwargs)

        self.default_path_lookups = default_path_lookups

    def convert(self, value, param, ctx):
        if value in self.default_path_lookups:
            value = self.default_path_lookups[value]()

        return super().convert(value, param, ctx)


host_base_dir_option = click.option(
    "--host-base-dir",
    help=(
        "Absolute path to use for docker volumes (only relevant when run from inside a docker "
        "container itself)"
    ),
    type=click.Path(),  # Can not check for exist, because path is on host
    default=None,
)


def project_name_option(**kwargs):
    return click.option(
        "--project-name",
        help="The project name. This will be used to namespace the docker containers (<project-name>_<service-name>)",
        show_default=True,
        **kwargs,
    )


def base_dir_option(**kwargs):
    return click.option(
        "-d",
        "--base-dir",
        help="Path where everything is installed into",
        type=click.Path(file_okay=False),
        show_default=True,
        **kwargs,
    )


@click.group()
def main():
    """Script to guide you through the quick setup of a Trustlines Blockchain node."""
    pass


@main.command()
@project_name_option(default="tlbc")
@base_dir_option(default="tlbc")
@host_base_dir_option
def tlbc(host_base_dir, project_name, base_dir):
    """
    Setup with Trustlines Blockchain settings.

    Setup the services for the Trustlines Blockchain with default settings.
    """

    run(
        chain_name="tlbc",
        base_dir=base_dir,
        host_base_dir=host_base_dir,
        project_name=project_name,
    )


@main.command()
@project_name_option(default="laika")
@base_dir_option(default="laika")
@host_base_dir_option
def laika(host_base_dir, project_name, base_dir):
    """
    Setup with Laika settings.

    Setup the services for the Laika testnet network with default settings.
    """
    run(
        chain_name="laika",
        host_base_dir=host_base_dir,
        base_dir=base_dir,
        project_name=project_name,
    )


def run(
    chain_name, base_dir, host_base_dir=None, project_name=None,
):
    click.echo("Starting account setup.")
    node_account.setup_interactively(base_dir=base_dir, chain_dir=chain_name)
    click.echo("Account setup complete.\n")
    click.echo("Starting e2e configs setup.")
    setup.setup(
        chain_name=chain_name, base_dir=base_dir,
    )
    click.echo("E2e configs setup complete.\n")
    click.echo("Starting the e2e containers.")
    start(
        base_dir=base_dir, host_base_dir=host_base_dir, chain_name=chain_name,
    )

    click.secho(
        "The setup was successful!\n"
        "You are currently running the Trustlines system.\n",
        fg="green",
    )
    click.echo(
        "You can stop the system by stopping the containers.\n"
        "To do that, cd into the created folder and run `docker-compose down`.\n"
    )
    click.echo(
        "You can restart the system by running the script `run-e2e.sh`.\n"
        "To do that, cd into the created folder and run `./run-e2e.sh`.\n"
    )


if __name__ == "__main__":
    main()
