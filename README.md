# end2end

This directory contains the files needed to run the clientlib's end2end tests
inside docker.

This script uses the [trustlines/e2e docker
image](https://hub.docker.com/r/trustlines/e2e/tags), which is automatically
being build from the clientlib repository.

## Installation

Please use a git checkout of the repo, either call the `run-e2e.sh` script with a
full path or put a symlink to the `run-e2e.sh` script into your `PATH`. The
following assumes you have put a symlink into your `PATH`.

Do not copy the script itself to `PATH`, it will not work.

## Running the tests

Just call

    run-e2e.sh

to start running the tests.

If you start with the `-p` option, the script will call docker-compose pull in
order to fetch the latest docker images.

## Using a local docker image

Just build and tag the image locally. For the relay server this looks like

    cd /path/to/relay
    docker build . -t relay
    docker tag relay trustlines/relay

## Running the end2end tests locally

The `-l` option starts tests locally via yarn. The relay server, parity and
postgres are still being run via docker-compose. You must be in the clientlib's
root folder to start with this option:

    cd /path/to/clientlib
    yarn install
    run-e2e.sh -l

## Running only the backend

If you only want to run the backend without automatically running the e2e tests,
use the option `-b`. This can be used for running the e2e tests manually.

## Running tests with delegation fees
If you want to run tests with delegation fees provided the `-f` flag.
