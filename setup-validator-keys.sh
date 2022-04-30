#!/usr/bin/bash

set -e

# Create Validator Account and Tuner
PATH="/usr/share/solana-release/bin:$PATH"
solana-keygen new -o ${SOLANA_HOME}/validator-keypair.json
solana-sys-tuner --user ${SOLANA_USER}> ${SOLANA_HOME}/sys-tuner.log 2>&1 &
