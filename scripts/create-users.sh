#!/usr/bin/env bash
set -e
set -o pipefail

# Creates user accounts, sets password, and apply read only policy
for u in kevin adam; do
  echo "creating user for $u"
  vault write auth/userpass/users/$u password=password policies=postgresql-readonly
done
