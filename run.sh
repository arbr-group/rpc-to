#!/usr/bin/bash

set -e

chmod +x env.sh
chmod +x setup-caddy.sh

chmod +x setup-user.sh
chmod +x setup-solana.sh

chmod +x setup-validator.sh
chmod +x setup-service.sh
chmod +x setup-validator-keys.sh

sh setup-caddy.sh
sh setup-solana.sh
sh setup-user.sh
sh setup-validator-keys.sh
sh setup-validator.sh
sh setup-service.sh

systemctl enable --now sol
