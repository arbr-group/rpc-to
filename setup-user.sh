#!/usr/bin/bash

set -e

. ./env.sh

# Create RPC User
sudo adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}"

# Give User Access to Dir
sudo chown -R ${SOLANA_USER}:${SOLANA_USER} ${SOLANA_HOME}
sudo -iu ${SOLANA_USER} mkdir -p ${SOLANA_HOME}/ledger
