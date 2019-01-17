# end2end

This directory contains the files needed to run the clientlib's end2end tests
inside docker.

This is a bit experimental.as it relies on a manually updated trustlines/e2e docker image.

## Running the tests

Just call

    ./run-e2e.sh

to start running the tests.


## Using a local docker image

Just build and tag the image locally. For the relay server this looks like

    cd /path/to/relay
    docker build . -t relay
    docker tag relay trustlines/relay
