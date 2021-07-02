#! /bin/bash

# Treat unset variables as an error when substituting.
set -u
# Exit on error
set -e

function die() {
  echo "$1"
  exit 1
}

E2E_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
cd "${E2E_DIR}" || die "cd failed"

trap "exit 1" SIGINT SIGTERM

# unset environment variables set in .env, otherwise we overwrite .env
unset PGHOST PGUSER POSTGRES_USER PGDATABASE PGPASSWORD POSTGRES_PASSWORD

docker-compose up --no-start
docker-compose up helper
docker cp addresses.json e2e-helper:/shared
docker-compose up -d postgres
docker-compose up -d home-node

sleep 5

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
