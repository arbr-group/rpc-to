#!/usr/bin/bash

set -ex

# https://github.com/solana-labs/solana/releases
VERSION=1.9.16
SOLANA_HOME=/sol
SOLANA_USER=sol
CLUSTER=devnet
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
SERVICE_NAME=wonka
SERVICE_FILE=/etc/systemd/system/${SERVICE_NAME}.service

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

/usr/share/solana-release/solana config set --url http://api.${CLUSTER}.solana.com
/usr/share/solana-release/solana config set --keypair ${SOLANA_HOME}/validator-keypair.json

# setup new user
adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}" || true

# create run script
sudo cat > ${RUN_SCRIPT} <<EOL
#!/usr/bin/bash

exec solana-validator \
    --enable-rpc-transaction-history \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
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
    --rpc-port 8899
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
sudo cat > ${SERVICE_FILE} <<EOL
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

systemctl enable --now ${SERVICE_NAME}