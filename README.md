# End2end

This directory contains the files needed to run the
[clientlib's end2end tests](https://github.com/trustlines-protocol/clientlib/tree/master/tests/e2e) inside docker.

The goal is to test that the different components making the Trustlines protocol work together.
It will run:
 - A development openethereum node that automatically mine a block when it receives a transaction
 - A [relay server](https://github.com/trustlines-protocol/relay).
 - A [py-eth-index](https://github.com/trustlines-protocol/py-eth-index) instance to index events for the relay.
 - A [contracts](https://github.com/trustlines-protocol/contracts) docker image that will deploy test
 currency networks, exchanges, and identity contracts.
 - The end2end tests from the [clientlib](https://github.com/trustlines-protocol/clientlib/tree/master/tests/e2e) repository

To have more information about Trustlines in general, visit the
[Trustlines Foundation website](https://trustlines.network/).

## Get Up and Running

Please use a git checkout of the repo, either call the `run-e2e.sh` script with a
full path or put a symlink to the `run-e2e.sh` script into your `PATH`. The
following assumes you have put a symlink into your `PATH`.

Do not copy the script itself to `PATH`, it will not work.

Just call `run-e2e.sh` to start running the tests.

### Pulling latest images

You can start the end2end script `-p` option, the script will call docker-compose pull in
order to fetch the latest docker images.

### Running tests against specific (relay, clientlib, index, contracts) versions

If you want to use a specific image (locally or from docker hub) you can use environment
variables to configure the image. The following env vars exist with their respective defaults.

    TL_RELAY_IMAGE=trustlines/relay
    TL_INDEX_IMAGE=trustlines/py-eth-index
    TL_CONTRACTS_IMAGE=trustlines/contracts
    TL_E2E_IMAGE=trustlines/e2e

You can provide the env variables either via an `.env` file beside the docker-compose file
or directly. For more information check the docker-compose documentation.
To run the tests against for example a different relay version, the command is

    TL_RELAY_IMAGE=trustlines/relay:0.14.0 ./run-e2e.sh

### Running the end2end tests locally

The `-l` option starts tests locally via yarn. The relay server, openethereum and
postgres are still being run via docker-compose. You must be in the clientlib's
root folder to start with this option:

    cd /path/to/clientlib
    yarn install
    run-e2e.sh -l

### Running only the backend

If you only want to run the backend without automatically running the e2e tests,
use the option `-b`. This can be used for running the e2e tests manually.

This can also be used to easily try out the Trustlines system for example by sending direct requests to the relay
server api on http://localhost:5000/api/v1/, or by playing around with the [clientlib](https://github.com/trustlines-protocol/clientlib).

See [the relay api documentation](https://github.com/trustlines-protocol/relay/blob/master/docs/RelayAPI.md)
or the [clientlib repository](https://github.com/trustlines-protocol/clientlib) for more information.

### Running tests with delegation fees

If you want to run tests with delegation fees provided the `-f` flag.
