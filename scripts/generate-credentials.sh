#!/usr/bin/env bash
set -e
set -o pipefail

# create some dynamic database credentials
for u in kevin adam; do
  echo "Generating Credentials for $u"
  vault login \
    -method=userpass \
    -no-print \
    username="$u" \
    password=password

  for i in {1..3}; do
    vault read database/creds/readonly
  done
done

vault login root
