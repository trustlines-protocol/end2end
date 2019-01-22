# end2end

This directory contains the files needed to run the clientlib's end2end tests
inside docker.

This is a bit experimental.as it relies on a manually updated trustlines/e2e docker image.

## Running the tests

Just call

    ./run-e2e.sh

to start running the tests.

If you start with the `-p` option, the script will call docker-compose pull in
order to fetch the latest docker images.

## Using a local docker image

Just build and tag the image locally. For the relay server this looks like

    cd /path/to/relay
    docker build . -t relay
    docker tag relay trustlines/relay

## Running the end2end tests locally

The '-l' option starts tests locally via yarn. The relay server, parity and
postgres are still being run via docker-compose. You must be in the clientlib's
root folder to start with this option:

    cd /path/to/clientlib
    yarn install
    /path/to/end2end/run-e2e.sh -l
