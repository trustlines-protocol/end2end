#! /bin/bash

NYC_OUTPUT_DIR=.nyc_output

set -u

function die()
{
    echo $1
    exit 1
}

OPTIND=1         # Reset in case getopts has been used previously in the shell.
cwd=$(pwd)
# Initialize our own variables:
use_local_yarn=0
pull=0
coverage=0
while getopts "lpc" opt; do
    case "$opt" in
        l)  use_local_yarn=1
            test -e src/Trustline.ts || die "run-e2e.sh: local test runs must be started from the clientlib repository"
            ;;
        p)  pull=1
            ;;
        c)  coverage=1
            ;;
    esac
done

set -x

function cleanup()
{
    cd $E2E_DIR
    docker-compose down -v
    rm -r $mydir
}

E2E_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
cd $E2E_DIR
if test $pull -eq 1; then
    docker-compose pull
fi

mydir=$(mktemp -td end2end.XXXXXX)
trap "cleanup" EXIT
trap "exit 1" SIGINT SIGTERM

# source .env in case we have the environment variables set locally
source .env

docker-compose up --no-start
docker-compose up helper
docker cp config.json e2e-helper:/shared
docker cp parity-dev-pw e2e-helper:/shared
docker-compose up -d postgres parity

sleep 5
docker-compose up contracts
docker-compose up createtables
docker-compose up init
docker-compose up -d index relay
sleep 3
docker-compose logs -t -f parity index relay e2e &

if test $use_local_yarn -eq 0; then
    docker-compose up -d e2e
    result=$(docker wait e2e)
    docker-compose logs -t e2e >$mydir/output.txt
    cd $cwd
    if test $coverage -eq 1; then
        rm -rf "$NYC_OUTPUT_DIR"
        docker cp e2e:/clientlib/"$NYC_OUTPUT_DIR"/. "$NYC_OUTPUT_DIR"
    fi
else
    cd $cwd
    yarn run test:e2e | tee $mydir/output.txt
    result="${PIPESTATUS[0]}"
fi
cat $mydir/output.txt
exit $result
