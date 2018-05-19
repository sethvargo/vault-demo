# Vault Demo

This README contains the steps I take when demoing Vault. I usually change
things up a bit here and there, but the content is generally like this.

If you're looking for instructions for running HashiCorp Vault, check out
[sethvargo/vault-on-gke](https://github.com/sethvargo/vault-on-gke).

## Getting Started

First we need to configure our local client to talk to the remote Vault server

```
export VAULT_DEV_ROOT_TOKEN_ID=root
export VAULT_ADDR=http://127.0.0.1
```

This server is not designed to be a "best-practices" Vault server and is mostly
designed for demonstrations such as this. It is not production ready. Please do
not use this Vault setup in production.

Start the Vault server

```
vault server -dev
```

Open a new tab or background the process.

## Authentication

The first thing we need to do is authenticate to the Vault. Because this Vault
is completely unconfigured, we need to use the root token to get started.
Normally this is a random UUID, but we cheated and made it "root" to make the
demo easier.

```
vault login root
```

Create some users who will authenticate to Vault.

```
./scripts/create-users.sh
```


## Static Secrets

There are two kinds of secrets in Vault - static and dynamic. Dynamic secrets
have enforced leases and usually expire after a short period of time. Static
secrets are refresh intervals, but they do not expire unless explicitly removed.

The easiest way to think about static secrets is "encrypted redis" or "encrypted
memcached". Vault exposes an encrypted key-value store such that all data
written is encrypted and stored.

Let's go ahead and write, read, update, and delete some static secrets:

```
vault kv put secret/foo a=b
```

Read a secret

```
vault kv get secret/foo
```

Show versioning

```
vault kv put secret/foo c=d
vault kv get secret/foo
vault kv get -version=1 secret/foo
```

Delete

```
vault kv delete secret/foo
```

## Transit

The transit backend provides "encryption as a service" and allows round-tripping
of data through Vault. This data is never actually stored in Vault, so the
memory footprint is relatively low (as compared with the generic secret backend,
for example). The transit backend behaves very similar a cloud KMS service

```
vault secrets enable transit
```

Create an encryption key

```
vault write -f transit/keys/myapp
```

Encrypt some data (base64)

```
vault write transit/encrypt/myapp plaintext=$(base64 <<< "hi")
```

Decrypt that data

```
vault write transit/decrypt/myapp ciphertext="..."
```

The transit endpoint supports key rotation as well. Trigger a key rotation:

```
vault write -f transit/keys/my-app/rotate
```

This will add a new encryption key to a ring, and data will be upgraded to the new version on the fly automatically. We could optionally have an application that iterates through the data and "rewraps" to the new encryption key. The advantage to the rewrap endpoint is that we never disclose the plaintext to the process - both the input and output are ciphertext. Here is what that looks like:

```
vault write transit/rewrap/myapp ciphertext=...
```

We could have a relatively un-trusted process perform the rewrap operation, because it never discloses the plaintext.

Lastly, it may be tempting to have per-row encryption keys (like in a database).
However, you should not do this. That means Vault needs to maintain one
encryption key per row, and that will bloat over time. Instead you can use
[derived keys](https://www.vaultproject.io/docs/secrets/transit/), which allow a
per-context encryption value.


## Database

Start postgres (requires docker)

```
./scripts/start-postgres.sh
```

Enable the database secrets engine

```
vault secrets enable database
```

Configure the database connection and role

```
cat scripts/configure-database.sh
```

- Explain role mapping to credentials (like a symlink)
- Explain ttl

```
./scripts/configure-database.sh
```

Generate a new database credential

```
vault read database/creds/readonly
```

Do this a few times to showcase real production

```
./scripts/generate-credentials.sh
```

Show

```
psql -h localhost -U postgres
\du
\q
```

Oh no - chris is evil - let's revoke everything

```
vault token revoke -mode=path auth/userpass/login/chris
```

```
psql -h localhost -U postgres
\du
\q
```

Serious data breach

```
vault lease revoke -prefix database/
```

## TOTP

```
vault secrets enable totp
```

Create a key (your app would make an API call to vault for this)

```
vault write totp/keys/seth \
  generate=true \
  issuer=MyApp \
  account_name=seth@sethvargo.com
```

QR code

```
echo "..." | base64 --decode > qr.png
```

Scan into 1password

...

Authenticate

```
vault write totp/code/seth code=...
```
