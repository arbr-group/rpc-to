#!/usr/bin/bash

set -ex

# https://github.com/solana-labs/solana/releases
VERSION=1.10.11
SOLANA_HOME=/sol
SOLANA_USER=sol
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
SERVICE=/etc/systemd/system/sol.service

# Update OS
apt-get update -qqy && apt-get install -qqy debian-keyring debian-archive-keyring apt-transport-https

# Install Caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qqy && apt-get install -qqy caddy

# Create Caddyfile
caddy adapt
systemctl restart caddy

# Install Solana CLI
cd "$(mktemp -d)" || exit
wget https://github.com/solana-labs/solana/releases/download/v${VERSION}/solana-release-x86_64-unknown-linux-gnu.tar.bz2
tar jxf solana-release-x86_64-unknown-linux-gnu.tar.bz2
mv solana-release /usr/share/

# Create RPC User
adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}"

# Create Run Script
sudo cat > ${RUN_SCRIPT} <<EOL
#!/usr/bin/bash
solana config set --url mainnet-beta &&
solana-validator \
    --rpc-threads $(nproc) \
    --accounts ${SOLANA_HOME}/accounts \
    --dynamic-port-range 8000-8100 \
    --enable-rpc-transaction-history \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --full-rpc-api \
    --identity ${SOLANA_HOME}/validator-keypair.json \
    --ledger ${SOLANA_HOME}/ledger \
    --log ${SOLANA_HOME}/solana-validator.log \
    --no-port-check \
    --no-voting \
    --rpc-bind-address 127.0.0.1 \
    --rpc-port 8899 \
    --limit-ledger-size
    --wal-recovery-mode skip_any_corrupted_record
EOL

chmod +x ${RUN_SCRIPT}

# Create Service
sudo cat > ${SERVICE} <<EOL
[Unit]
Description=Solana Validator
After=network.target
Wants=solana-sys-tuner.service
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=${SOLANA_USER}
LimitNOFILE=1000000
LogRateLimitIntervalSec=0
Environment="PATH=/bin:/usr/bin:/usr/share/solana-release/bin"
ExecStart=${RUN_SCRIPT}

[Install]
WantedBy=multi-user.target
EOL

# Create Validator Account and Tuner
PATH="/usr/share/solana-release/bin:$PATH"
solana-keygen new -o ${SOLANA_HOME}/validator-keypair.json
solana-sys-tuner --user ${SOLANA_USER}> ${SOLANA_HOME}/sys-tuner.log 2>&1 &

# Give User Access to Dir
sudo chown -R ${SOLANA_USER}:${SOLANA_USER} ${SOLANA_HOME}
sudo -iu ${SOLANA_USER} mkdir -p ${SOLANA_HOME}/ledger

systemctl enable --now sol
