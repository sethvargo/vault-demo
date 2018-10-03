# Vault Demo

This repository contains the materials and demo for my **Modern Secrets
Management** with Vault talk. It has been given at a number of conferences and
meetups.

This README contains the steps I take when demoing Vault. I usually change
things up a bit here and there, but the content is generally like this. The
steps here are for demo purposes and **may not represent best practices!**

If you want to run HashiCorp Vault in production, check out
[sethvargo/vault-on-gke](https://github.com/sethvargo/vault-on-gke).


## Getting Started

First, we need to configure our local client to talk to the remote Vault server:

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

Open a new terminal tab/session or background the process.


## Authentication

The first thing we need to do is authenticate to the Vault. Because this Vault
is completely unconfigured, we need to use the root token to get started.
Normally this is a random UUID, but we cheated and made it "root" to make the
demo easier.

```
vault login root
```

There are many ways to authenticate to Vault including GitHub,
username-password, LDAP, and more. There are also ways for machines to
authenticate such as AppID or TLS.

The root user is special and has all permissions in the system. Other users must
be granted access via policies, which we will explore in a bit.


## Create Users

Create some users who will authenticate to Vault. These users will
authentication with standard username and password.

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

Rollback

```
vault kv rollback -version=1 secret/foo
vault kv get secret/foo
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

The advantage here is that applications do not need to know how to do asymmetric
encryption nor do they applications even know the encryption key. An attacker
would need to compromise multiple systems to decrypt the data.

```
vault secrets enable transit
```

Create an encryption key. You can think of the name "myapp" as a symlink or
pointer to the actual encryption key.

```
vault write -f transit/keys/myapp
```

Encrypt some data (base64). Now we can feed data into this named key, and Vault
will return the encrypted data. Because there is no requirement the data be
"text", we need to pass base64-encoded data.

```
vault write transit/encrypt/myapp plaintext=$(base64 <<< "hi")
```

Vault returns the base64-encoded ciphertext. This ciphertext can be stored in
our database or filesystem. When our application needs the plaintext value, it
can post the encrypted value and get the plaintext back.

Decrypt that data.

```
vault write transit/decrypt/myapp ciphertext="..."
```

The transit endpoint supports key rotation as well. Trigger a key rotation:

```
vault write -f transit/keys/myapp/rotate
```

This will add a new encryption key to a ring, and data will be upgraded to the
new version on the fly automatically. We could optionally have an application
that iterates through the data and "rewraps" to the new encryption key. The
advantage to the rewrap endpoint is that we never disclose the plaintext to the
process - both the input and output are ciphertext. Here is what that looks
like:

```
vault write transit/rewrap/myapp ciphertext=...
```

We could have a relatively un-trusted process perform the rewrap operation,
because it never discloses the plaintext.

Lastly, it may be tempting to have **per-row encryption keys** (like in a
database). However, you should not do this. That means Vault needs to maintain
one encryption key per row, and that will bloat over time. Instead you can use
[derived keys](https://www.vaultproject.io/docs/secrets/transit/), which allow a
per-context encryption value.


## Database

Vault also has the ability to _generate_ secrets. These are called "dynamic"
secrets. Unlike static secrets, dynamic secrets have an expiration, called a
lease. At the end of this lease, the credential is revoked. This prevents secret
sprawl and significantly reduces the attack surface. Instead of a database
password living in a text file for 6 months, it can be dynamically generated
every 30 minutes!

Start postgres (requires Docker). This example uses a local Postgres instance,
but this could easily be a Google Cloud SQL instance or other hosted database
service.

```
./scripts/start-postgres.sh
```

Enable the database secrets engine.

```
vault secrets enable database
```

Configure the database connection and role.

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

Login as one of our users and generate:

```
vault login -method=userpass username=chris password=password
vault read database/creds/readonly
```

Log back in as the root user:

```
vault login root
```

Do this a few times to showcase real production

```
./scripts/generate-credentials.sh
```

Show

```
psql
\du
\q
```

Oh no - chris and devin are evil - let's revoke everything

```
vault token revoke -mode=path auth/userpass/login/chris
vault token revoke -mode=path auth/userpass/login/devin
```

```
psql
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

Sign into 1password

...

Authenticate

```
vault write totp/code/seth code=...
```


## Plugin

Vault can be extended with plugins. A popular third-party plugin is a plugin
that generates passwords and passphrases for use on websites similar to
1Password or LastPass called "vault-secrets-gen".

Note that the plugin is "enabled" or "mounted" at `gen/`. That means all
requests to `gen/` go to the plugin. The plugin defines the supported paths.

To generate a new password:

```sh
$ vault write gen/password length=64
```

To generate a random passphrase using the diceware algorithm:

```sh
$ vault write -f gen/passphrase words=6
```
