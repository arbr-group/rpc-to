#!/usr/bin/bash

set -e

chmod +x env.sh
chmod +x setup-caddy.sh
chmod +x setup-solana.sh
chmod +x setup-user.sh
chmod +x setup-validator.sh
chmod +x setup-service.sh
chmod +x setup-validator-keys.sh

if [[ ! -e /etc/caddy/Caddyfile ]]; then
  echo "Setting up Caddy..."
  sh setup-caddy.sh
fi

if [[ ! -e $SOLANA ]]; then
  echo "Setting up Solana CLI..."
  sh setup-solana.sh
fi

if [[ -d $SOLANA_HOME ]]; then
  echo "Setting up User..."
  sh setup-user.sh
fi

if [[ ! -e $RUN_SCRIPT ]]; then
  echo "Setting up Validator..."
  sh setup-validator.sh
fi

echo "Setting up Systemctl Service..."
sh setup-service.sh

if [[ ! -e "${SOLANA_HOME}/validator-key.json" ]]; then
  echo "Setting up Credentials..."
  sh setup-validator-keys.sh
fi

echo "Starting Service..."
systemctl enable --now sol
