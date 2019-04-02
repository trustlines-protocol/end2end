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
only_backend=0
while getopts "lpcb" opt; do
    case "$opt" in
        l)  use_local_yarn=1
            test -e src/Trustline.ts || die "run-e2e.sh: local test runs must be started from the clientlib repository"
            ;;
        p)  pull=1
            ;;
        c)  coverage=1
            ;;
        b)  only_backend=1
            ;;
    esac
done


# Makes the bash script to print out every command before it is executed except echo
# this is a replacement for 'set -x'
function preexec ()
{
    [[ $BASH_COMMAND != echo* ]] && echo >&2 "+ $BASH_COMMAND"
}
set -o functrace   # run DEBUG trap in subshells
trap preexec DEBUG


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

if test $only_backend -eq 0; then
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
else
    echo
    echo "====================================================="
    echo "Initialization is complete."
    echo "You've started the script with the -b flag."
    echo "You can now run your tests manually."
    echo "Hit Ctrl-C when done."
    echo "====================================================="
    echo
    sleep 5
    docker-compose logs -t -f parity index relay
fi
