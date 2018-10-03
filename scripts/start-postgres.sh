#!/usr/bin/env bash
set -e
set -o pipefail

docker run -d -p 5432:5432 -e POSTGRES_DB=myapp postgres
echo "==> Done!"

export PGHOST="localhost"
export PGUSER="postgres"
export PGDATABASE="postgres"

exec "${SHELL}"
