# Download Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/v1.10.8/install)"

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
    --rpc-bind-address 0.0.0.0 \
    --no-voting \
    --wal-recovery-mode skip_any_corrupted_record \
    --entrypoint entrypoint.devnet.solana.com:8001 \
    --limit-ledger-size \
    --full-rpc-api \
    --log -