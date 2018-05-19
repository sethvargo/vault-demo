#!/usr/bin/env bash
set -e

for u in sally bobby chris devin; do
  vault login -method=userpass username="$u" password=password

  for i in {1..5}; do
    vault read database/creds/readonly
  done
done

vault login root
