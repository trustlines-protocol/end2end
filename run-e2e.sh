#! /bin/bash

NYC_OUTPUT_DIR=.nyc_output

set -u

function die() {
  echo "$1"
  exit 1
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.
cwd=$(pwd)
# Initialize our own variables:
use_local_yarn=0
pull=0
coverage=0
only_backend=0
use_delegation_fee=0
while getopts "lpcbf" opt; do
  case "$opt" in
  l)
    use_local_yarn=1
    [[ -e src/Trustline.ts ]] || die "run-e2e.sh: local test runs must be started from the clientlib repository"
    ;;
  p)
    pull=1
    ;;
  c)
    coverage=1
    ;;
  b)
    only_backend=1
    ;;
  f)
    use_delegation_fee=1
    ;;
  *)
    # illegal option case; getopt already shows an error message
    exit 1
    ;;
  esac
done

# Makes the bash script to print out every command before it is executed except echo
# this is a replacement for 'set -x'
function preexec() {
  [[ ${BASH_COMMAND} != echo* ]] && echo >&2 "+ ${BASH_COMMAND}"
}
set -o functrace # run DEBUG trap in subshells
trap preexec DEBUG

function cleanup() {
  cd "${E2E_DIR}" || die "cd failed"
  docker-compose down -v
  rm -r "${mydir}"
}

# Copies the file addresses.json in the shared volume to the local directory cwd/tests/e2e-config
function copySharedVolumeAddressesToLocalMachine() {
  echo "copy addresses from e2e-helper:/shared/addresses.json to $cwd/tests/e2e-config/"
  docker cp e2e-helper:/shared/addresses.json "$cwd/tests/e2e-config/"
}

E2E_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
echo "$E2E_DIR"
cd "${E2E_DIR}" || die "cd failed"
if [[ ${pull} -eq 1 ]]; then
  docker-compose pull
fi

mydir=$(mktemp -td end2end.XXXXXX)
trap "cleanup" EXIT
trap "exit 1" SIGINT SIGTERM

# unset environment variables set in .env, otherwise we overwrite .env
unset PGHOST PGUSER POSTGRES_USER PGDATABASE PGPASSWORD POSTGRES_PASSWORD

docker-compose up --no-start
docker-compose up helper
docker cp keys e2e-helper:/shared/keystore
docker-compose up -d db node

sleep 5
docker-compose up contracts

# copies the addresses.json file out to get a contract's address in the relay's config.toml
docker cp e2e-helper:/shared/addresses.json .

relay_config=config.toml
address_file=addresses.json

if [[ ${use_delegation_fee} -eq 1 ]]; then
  delegation_fee_network=$(sed -E 's/\{"networks": \["(0x[0-9,a-f,A-F]+)".*/\1/' $address_file)
  delegation_fee_option=$(
    cat <<EOF
[[delegate.fees]]
base_fee = 1
gas_price = 1000
currency_network = "${delegation_fee_network}"
EOF
  )
else
  delegation_fee_option=$(
    cat <<EOF
[[delegate.fees]]
base_fee = 0
gas_price = 0
EOF
  )
fi

cat >${relay_config} <<EOF
[account]
keystore_path = "/shared/keystore/key"
keystore_password_path = "/shared/keystore/password"

[relay]
addresses_filepath = "/shared/addresses.json"

[relay.gas_price_computation]
method = "rpc"
gas_price = 0

[trustline_index]
enable = true
sync_interval = 1

[tx_relay]
enable = true

[exchange]
enable = true

[node_rpc]
host = "node"
port = 8545
use_ssl = false

[faucet]
enable = true

[push_notification]
enable = false

[rest]
port = 5000
host = "relay"

[messaging]
enable = true

[delegate]
enable = true
enable_deploy_identity = true

[logging]
level = "DEBUG"

[logging.loggers."signing_middleware"]
level = "DEBUG"

$delegation_fee_option
EOF

rm -f $address_file

docker cp config.toml e2e-helper:/shared
docker cp node.log e2e-helper:/shared

docker-compose up createtables
docker-compose up init
docker-compose up -d index relay

docker-compose up -d nginx safe-relay-service worker scheduler

if [[ ${only_backend} -eq 0 ]]; then
  sleep 3
  docker-compose logs -t -f node index relay e2e &
  if [[ ${use_local_yarn} -eq 0 ]]; then
    docker-compose up -d e2e
    docker_wait_output=$(docker wait e2e)
    case ${docker_wait_output} in
    [0-9]*)
      result=${docker_wait_output}
      ;;
    *)
      result=1
      ;;
    esac
    docker-compose logs -t e2e >"${mydir}/output.txt"
    cd "${cwd}" || die "cd failed"
    if [[ ${coverage} -eq 1 ]]; then
      rm -rf "${NYC_OUTPUT_DIR}"
      docker cp e2e:/clientlib/"${NYC_OUTPUT_DIR}"/. "${NYC_OUTPUT_DIR}"
    fi
  else
    cd "${cwd}" || die "cd failed"
    copySharedVolumeAddressesToLocalMachine
    yarn run test:e2e | tee "${mydir}/output.txt"
    result="${PIPESTATUS[0]}"
  fi
  cat "${mydir}/output.txt"
  exit "${result}"
else
  copySharedVolumeAddressesToLocalMachine
  echo
  echo "====================================================="
  echo "Initialization is complete."
  echo "You've started the script with the -b flag."
  echo "You can now run your tests manually."
  echo "Hit Ctrl-C when done."
  echo "====================================================="
  echo
  sleep 5
  docker-compose logs -t -f node index relay nginx safe-relay-service worker scheduler
fi
