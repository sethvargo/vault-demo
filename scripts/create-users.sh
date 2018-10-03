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

docker ps &>/dev/null || {
  echo ""
  echo ""
  echo "Hey Seth - make sure Docker for Mac is running!"
  echo ""
  echo ""
}

docker image inspect postgres &>/dev/null || {
  echo ""
  echo ""
  echo "Hey Seth - it looks like the postgres Docker container is not"
  echo "downloaded. Are you on conference wifi? If so, you should start"
  echo "the download now before you move on so it finishes on time."
  echo ""
  echo ""
}
