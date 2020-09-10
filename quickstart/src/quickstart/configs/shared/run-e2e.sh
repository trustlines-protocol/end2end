#! /bin/bash

set -u

function die() {
  echo "$1"
  exit 1
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.
# Initialize our own variables:
pull=0
use_delegation_fee=0
while getopts "lpcbf" opt; do
  case "$opt" in
  p)
    pull=1
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

E2E_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
cd "${E2E_DIR}" || die "cd failed"
if [[ ${pull} -eq 1 ]]; then
  docker-compose pull
fi

trap "exit 1" SIGINT SIGTERM

# unset environment variables set in .env, otherwise we overwrite .env
unset PGHOST PGUSER POSTGRES_USER PGDATABASE PGPASSWORD POSTGRES_PASSWORD

docker-compose up --no-start
docker-compose up helper
docker cp addresses.json e2e-helper:/shared
docker cp contracts.json e2e-helper:/shared
docker-compose up -d postgres
docker-compose up -d home-node

sleep 5

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
[relay]
addresses_filepath = "/shared/addresses.json"
update_indexed_networks_interval = 5

[relay.gas_price_computation]
method = "rpc"
gas_price = 0

[trustline_index]
enable = true
full_sync_interval = 300

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

$delegation_fee_option
EOF

docker cp config.toml e2e-helper:/shared
docker-compose up -d createtables
docker-compose up -d init
docker-compose up -d index relay

echo
echo "====================================================="
echo "Initialization is complete."
echo "The Trustlines system is running."
echo "====================================================="
echo
exit 0
