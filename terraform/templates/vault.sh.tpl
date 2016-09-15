#!/usr/bin/env bash
set -e

# Update apt
sudo apt-get -qq update

# Install vault
sudo apt-get -yqq install curl unzip
curl -s -L -o "vault.zip" "https://releases.hashicorp.com/vault/0.6.1/vault_0.6.1_linux_amd64.zip"
unzip "vault.zip"
sudo mv "vault" "/usr/local/bin/vault"
sudo chmod +x "/usr/local/bin/vault"
sudo rm -rf "vault.zip"

# Install and configure postgresql
curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get -yqq update
sudo apt-get -yqq install postgresql postgresql-contrib
sudo tee /etc/postgresql/*/main/pg_hba.conf > /dev/null <<"EOF"
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
EOF
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
sudo service postgresql restart
psql -U postgres -c 'CREATE DATABASE myapp;'

# Set PS1
sudo tee /etc/profile.d/ps1.sh > /dev/null <<"EOF"
export PS1="\u@hashicorp > "
EOF
for d in /home/*; do
  if [ -d "$d" ]; then
    sudo tee -a $d/.bashrc > /dev/null <<"EOF"
export PS1="\u@hashicorp > "
EOF
  fi
done

# Set hostname for sudo
echo "${hostname}" | sudo tee /etc/hostname
sudo hostname -F /etc/hostname
sudo sed -i'' '1i 127.0.0.1 ${hostname}' /etc/hosts

# Setup Vault
sudo mkdir -p /opt/vault/data
BIND=$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')
sudo tee /opt/vault/config.hcl > /dev/null <<EOF
backend "file" {
  path = "/opt/vault/data"
}
EOF

# Start Vault on boot
BIND=$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')
sudo tee /etc/init/vault.conf > /dev/null <<"EOF"
description "Vault"

start on runlevel [2345]
stop on runlevel [06]

respawn

kill signal INT

env VAULT_DEV_ROOT_TOKEN_ID=root
env VAULT_DEV_LISTEN_ADDRESS=127.0.0.1:8200

exec /usr/local/bin/vault server \
  -dev \
  -config="/opt/vault/config.hcl"
EOF

# Upstart is weird
sleep 2
sudo service vault stop || true
sudo service vault start

# Setup nginx for proxying
sudo apt-get -yqq install nginx
sudo tee /etc/nginx/sites-enabled/default > /dev/null <<"EOF"
server {
  listen 80 default_server;
  listen [::]:80 default_server ipv6only=on;

  server_name vault.hashicorp.rocks;

  location / {
    proxy_pass http://127.0.0.1:8200;
    proxy_set_header Host $$host;
    expires -1;
  }
}
EOF
sudo service nginx reload
