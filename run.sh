#!/usr/bin/bash

VERSION=1.10.11
SOLANA_HOME=/sol
SOLANA_USER=sol
ENVIRONMENT=devnet
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
SOLANA=/usr/share/solana-release/bin/solana
SOLANA_VALIDATOR=/usr/share/solana-release/bin/solana-validator
SERVICE=/etc/systemd/system/sol.service

# Download Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Start Caddyfile
sudo cp Caddyfile /etc/caddy/Caddyfile
sudo caddy adapt --config /etc/caddy/Caddyfile
sudo systemctl restart caddy

# Get Solana Version and Install
cd "$(mktemp -d)" || exit
wget https://github.com/solana-labs/solana/releases/download/v${VERSION}/solana-release-x86_64-unknown-linux-gnu.tar.bz2
tar jxf solana-release-x86_64-unknown-linux-gnu.tar.bz2
sudo mv solana-release /usr/share/

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

# Create RPC User
sudo adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}"

# Give User Access to Dir
sudo chown -R ${SOLANA_USER}:${SOLANA_USER} ${SOLANA_HOME}
sudo -iu ${SOLANA_USER} mkdir -p ${SOLANA_HOME}/ledger

# Create Validator Account and Tuner
PATH="/usr/share/solana-release/bin:$PATH"
sudo solana-keygen new -o ${SOLANA_HOME}/validator-keypair.json
sudo olana-sys-tuner --user ${SOLANA_USER}> ${SOLANA_HOME}/sys-tuner.log 2>&1 &

 sudo systemctl enable --now sol