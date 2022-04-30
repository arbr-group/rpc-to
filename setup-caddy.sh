#!/usr/bin/bash

set -e

source env.sh

# Install Caddy
apt-get update -qqy && apt-get install -qqy debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qqy && apt-get install -qqy caddy

# Start Caddyfile
sudo cp Caddyfile /etc/caddy/Caddyfile
caddy adapt --config /etc/caddy/Caddyfile
systemctl restart caddy
