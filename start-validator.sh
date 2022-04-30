#!/bin/bash

set -e

sudo cat > ${RUN_SCRIPT} <<EOL
#!/usr/bin/bash
solana config set --url mainnet-beta &&
solana-validator \
    --entrypoint entrypoint.devnet.solana.com:8001 \
    --entrypoint entrypoint2.devnet.solana.com:8001 \
    --entrypoint entrypoint3.devnet.solana.com:8001 \
    --entrypoint entrypoint4.devnet.solana.com:8001 \
    --entrypoint entrypoint5.devnet.solana.com:8001 \
    --known-validator dv1ZAGvdsz5hHLwWXsVnM94hWf1pjbKVau1QVkaMJ92 \
    --known-validator dv2eQHeP4RFrJZ6UeiZWoc3XTtmtZCUKxxCApCDcRNV \
    --known-validator dv4ACNkpYPcE3aKmYDqZm9G5EB3J4MRoeE7WNDRBVJB \
    --known-validator dv3qDFk1DTF36Z62bNvrCXe9sKATA6xvVy6A798xxAS \
    --expected-genesis-hash EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG \
    --dynamic-port-range 8000-8020 \
    --rpc-port 8899 \
    --only-known-rpc \
    --wal-recovery-mode skip_any_corrupted_record \
    --identity ${SOLANA_HOME}/validator-keypair.json \
    --vote-account ${SOLANA_HOME}/vote-account-keypair.json \
    --log ${SOLANA_HOME}/log/validator.log \
    --accounts /mnt/ramdisk/solana-accounts \
    --ledger ${SOLANA_HOME}/ledger \
    --limit-ledger-size
EOL

chmod +x ${RUN_SCRIPT}
