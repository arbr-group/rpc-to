


sh -c "$(curl -sSfL https://release.solana.com/v1.10.8/install)"

. ~/.profile

solana config set --url http://api.devnet.solana.com

sudo $(command -v solana-sys-tuner) --user $(whoami) > sys-tuner.log 2>&1 &

solana-keygen new -o ~/validator-keypair.json --no-bip39-passphrase

solana config set --keypair ~/validator-keypair.json

solana airdrop 1
