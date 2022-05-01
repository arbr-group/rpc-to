#!/usr/bin/bash

set -e

sudo apt update

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

# Download Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/v1.10.11/install)"

. ~/.profile

# Set to Solana Environment
solana config set --url http://api.devnet.solana.com

# Tuner
sudo $(command -v solana-sys-tuner) --user $(whoami) > sys-tuner.log 2>&1 &

# Create Identity
solana-keygen new -o ~/validator-keypair.json --no-bip39-passphrase
solana config set --keypair ~/validator-keypair.json

# Fauecet
solana airdrop 1

# Run Validator
solana-validator \
    --identity ~/validator-keypair.json \
    --rpc-port 8899 \
    --no-voting \
    --rpc-bind-address 0.0.0.0 \
    --dynamic-port-range 8000-8020 \
    --no-port-check \
    --entrypoint entrypoint.devnet.solana.com:8001 \
    --entrypoint entrypoint2.devnet.solana.com:8001 \
    --entrypoint entrypoint3.devnet.solana.com:8001 \
    --limit-ledger-size \
    --full-rpc-api \
    --log -