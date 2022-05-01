#!/bin/bash

set -e

. ./env.sh

sudo cat > ${RUN_SCRIPT} <<EOL
#!/usr/bin/bash
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
    --log ${SOLANA_HOME}/validator.log
EOL

chmod +x ${RUN_SCRIPT}
