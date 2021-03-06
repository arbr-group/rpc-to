#!/usr/bin/bash

set -e

# https://github.com/solana-labs/solana/releases
VERSION=1.10.11
SOLANA_HOME=/sol
SOLANA_USER=sol
CLUSTER=devnet
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
SERVICE_NAME=sol

apt-get update

# install caddy
apt-get install -qqy debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qqy && apt-get install -qqy caddy
cat << EOT > /etc/caddy/Caddyfile
:80 {
  header -Server
  header Access-Control-Allow-Methods POST, OPTIONS
  header access-control-max-age 86400
  reverse_proxy localhost:8899
}
EOT
systemctl restart caddy

# install Solana
cd "$(mktemp -d)" || exit
wget https://github.com/solana-labs/solana/releases/download/v${VERSION}/solana-release-x86_64-unknown-linux-gnu.tar.bz2
tar jxf solana-release-x86_64-unknown-linux-gnu.tar.bz2
rm -rf /usr/share/solana-release/
mv solana-release /usr/share/

# setup new user
adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}" || true

# create run script
sudo cat > ${RUN_SCRIPT} <<EOL
#!/usr/bin/bash

solana-validator \
    --entrypoint entrypoint.devnet.solana.com:8001 \
    --entrypoint entrypoint2.devnet.solana.com:8001 \
    --entrypoint entrypoint3.devnet.solana.com:8001 \
    --entrypoint entrypoint4.devnet.solana.com:8001 \
    --entrypoint entrypoint5.devnet.solana.com:8001 \
    --expected-genesis-hash EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG \
    --known-validator dv1ZAGvdsz5hHLwWXsVnM94hWf1pjbKVau1QVkaMJ92 \
    --known-validator dv2eQHeP4RFrJZ6UeiZWoc3XTtmtZCUKxxCApCDcRNV \
    --known-validator dv4ACNkpYPcE3aKmYDqZm9G5EB3J4MRoeE7WNDRBVJB \
    --known-validator dv3qDFk1DTF36Z62bNvrCXe9sKATA6xvVy6A798xxAS \
    --wal-recovery-mode skip_any_corrupted_record \
    --only-known-rpc \
    --account-index \
    --accounts ${SOLANA_HOME}/accounts \
    --identity ${SOLANA_HOME}/validator-keypair.json \
    --ledger ${SOLANA_HOME}/ledger \
    --limit-ledger-size
    --log ${SOLANA_HOME}/solana-validator.log \
    --no-port-check \
    --no-voting \
    --full-rpc-api \
    --rpc-bind-address 127.0.0.1 \
    --rpc-threads $(nproc) \
    --rpc-port 8899 \
    --dynamic-port-range 8000-8020 \
EOL

# make executable
chmod +x ${RUN_SCRIPT}

# log rotation
cat << EOT > /etc/logrotate.d/sol
${SOLANA_HOME}/solana-validator.log {
  rotate 4
  daily
  missingok
  postrotate
    systemctl kill -s USR1 ${SERVICE_NAME}.service
  endscript
}
EOT
systemctl restart logrotate.service

# create systemd
sudo cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOL
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

# create a validator account and enable sys-tuner
export PATH="/usr/share/solana-release/bin:$PATH"
solana-keygen new -o ${SOLANA_HOME}/validator-keypair.json --no-bip39-passphrase || true
solana-sys-tuner --user ${SOLANA_USER}> ${SOLANA_HOME}/sys-tuner.log 2>&1 &

# make sure solana owns its own data dir
sudo chown -R ${SOLANA_USER}:${SOLANA_USER} ${SOLANA_HOME}
sudo -iu ${SOLANA_USER} mkdir -p ${SOLANA_HOME}/ledger

systemctl enable --now ${SERVICE_NAME}.service