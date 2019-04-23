#!/usr/bin/env bash
set -e
set -o pipefail

# PostgreSQL is one of the supported plugins for the database secrets engine.
# This plugin generates database credentials dynamically based on configured
# roles for the PostgreSQL database.
# https://www.vaultproject.io/docs/secrets/databases/postgresql.html

# Enable database secrets engine
vault secrets enable database

# Configure Vault with the proper plugin and connection information
vault write database/config/my-postgresql-database \
  plugin_name="postgresql-database-plugin" \
  allowed_roles="readonly" \
  connection_url="postgresql://postgres@127.0.0.1:5432?sslmode=disable" \

# Configure a role that maps a name in Vault to an SQL statement to create
# dynamic credentials

# {{name}} fields will be populated by the plugin
vault write database/roles/readonly \
  db_name="my-postgresql-database" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="15m" \
  max_ttl="24h"

# create a policy
vault policy write postgresql-readonly -<<EOF
path "database/creds/readonly" {
  capabilities = ["read"]
}
EOF

# Enable users to authenticate with user/password
vault auth enable userpass
