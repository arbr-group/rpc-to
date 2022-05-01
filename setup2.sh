


sh -c "$(curl -sSfL https://release.solana.com/v1.10.8/install)"

. ~/.profile

solana config set --url http://api.devnet.solana.com

sudo $(command -v solana-sys-tuner) --user $(whoami) > sys-tuner.log 2>&1 &

solana-keygen new -o ~/validator-keypair.json --no-bip39-passphrase

solana config set --keypair ~/validator-keypair.json

solana airdrop 1

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
    --known-validator Cogent51kHgGLHr7zpkpRjGYFXM57LgjHjDdqXd4ypdA \
    --known-validator 12ashmTiFStQ8RGUpi1BTCinJakVyDKWjRL6SWhnbxbT \
    --known-validator 1aine15iEqZxYySNwcHtQFt4Sgc75cbEi9wks8YgNCa \
    --known-validator FXrzBb4KBTiQsVdSprYtKE4nZUvQWc7rgG5Z2BF9mUXd \
    --known-validator SerGoB2ZUyi9A1uBFTRpGxxaaMtrFwbwBpRytHefSWZ \
    --known-validator 2kVZVTY8FMRZ3WuHzyqNz8qd4Ytbba9f9DaesUm5WLvR \
    --known-validator Cu9Ls6dsTL6cxFHZdStHwVSh1uy2ynXz8qPJMS5FRq86 \
    --known-validator CMPSSdrTnRQBiBGTyFpdCc3VMNuLWYWaSkE8Zh5z6gbd \
    --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
    --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
    --known-validator FSVdqBzx5D4UsqBLnvmH5dFx2dCm1pTPAbQWJ1PYzTJ2 \
    --known-validator FLVgaCPvSGFguumN9ao188izB4K4rxSWzkHneQMtkwQJ \
    --identity ~/validator-keypair.json \
    --rpc-port 8899 \
    --entrypoint entrypoint.devnet.solana.com:8001 \
    --limit-ledger-size \
    --log ~/solana-validator.log
    --dynamic-port-range 8000-8020 \
    --rpc-port 8899 \
    --only-known-rpc \
    --wal-recovery-mode skip_any_corrupted_record
    --log -