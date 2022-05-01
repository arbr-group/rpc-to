#!/usr/bin/bash

VERSION=1.10.11
SOLANA_HOME=/sol
SOLANA_USER=sol
ENVIRONMENT=devnet
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
SOLANA=/usr/share/solana-release/bin/solana
SOLANA_VALIDATOR=/usr/share/solana-release/bin/solana-validator
SERVICE=/etc/systemd/system/sol.service
