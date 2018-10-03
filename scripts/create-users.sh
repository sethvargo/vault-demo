#!/usr/bin/env bash
set -e
set -o pipefail

vault policy write postgresql-readonly -<<EOF
path "database/creds/readonly" {
  capabilities = ["read"]
}
EOF

vault auth enable userpass
for u in sally bobby chris devin; do
  vault write auth/userpass/users/$u password=password policies=postgresql-readonly
done
