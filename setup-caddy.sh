#!/usr/bin/bash

set -e

. ./env.sh

# Download Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Start Caddyfile
sudo cp Caddyfile /etc/caddy/Caddyfile
sudo caddy adapt --config /etc/caddy/Caddyfile
sudo systemctl restart caddy