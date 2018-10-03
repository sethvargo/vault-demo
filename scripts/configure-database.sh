#!/usr/bin/env bash
set -e
set -o pipefail

vault write database/config/my-postgresql-database \
  plugin_name="postgresql-database-plugin" \
  allowed_roles="readonly" \
  connection_url="postgresql://postgres@127.0.0.1:5432?sslmode=disable" \

vault write database/roles/readonly \
  db_name="my-postgresql-database" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="15m" \
  max_ttl="24h"
