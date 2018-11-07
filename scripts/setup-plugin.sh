#!/usr/bin/env bash
set -e
set -o pipefail

mkdir -p plugins/
cd plugins/
if [[ ! -f vault-secrets-gen ]]; then
  curl -sfSLo plugin.tgz https://github.com/sethvargo/vault-secrets-gen/releases/download/v0.0.2/vault-secrets-gen_0.0.2_darwin_amd64.zip
  tar -xzvf plugin.tgz
  rm -f plugin.tgz
fi
cd -

PLUGIN_SHA=$(shasum -a 256 "plugins/vault-secrets-gen" | cut -d " " -f1)
vault plugin register -sha256="${PLUGIN_SHA}" secret vault-secrets-gen

vault secrets enable -path=gen -plugin-name=vault-secrets-gen plugin
