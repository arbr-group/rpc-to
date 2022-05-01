#!/usr/bin/bash

function retry {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))
    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}

function restart_if_too_slow(){
  sleep 180
  avg_download_speed="$(grep solana_download_utils /fast/solana-validator.log | tail -10 | awk '{sum += $8} END {print int(int(sum/8)/1024/1024)}')"
  if [[ $avg_download_speed -lt 100 ]]; then
    systemctl restart sol
  fi
}

set -ex

# https://github.com/solana-labs/solana/releases
VERSION=1.9.16
SOLANA_HOME=/super
SOLANA_USER=cool
RUN_SCRIPT=${SOLANA_HOME}/validator.sh
UNGUESSABLE_STRING=2cb5dc45-2d25-45d9-aad0-a648955f27f8
SERVICE=/etc/systemd/system/sol.service

sleep 60 # wait for apt, sorry mom i know it's ghetto
# install caddy
apt-get update -qqy && apt-get install -qqy debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -qqy && apt-get install -qqy caddy
cat << EOT > /etc/caddy/Caddyfile
:80 {
  header -Server
  header Access-Control-Allow-Methods POST, OPTIONS
  header access-control-max-age 86400
  reverse_proxy /api/* localhost:8899
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
    --rpc-port 8899
EOL

# make executable
chmod +x ${RUN_SCRIPT}

# log rotation
cat << EOT > /etc/logrotate.d/sol
/fast/solana-validator.log {
  rotate 4
  daily
  missingok
  postrotate
    systemctl kill -s USR1 sol.service
  endscript
}
EOT
systemctl restart logrotate.service

# create systemd
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

# create a validator account and enable sys-tuner
export PATH="/usr/share/solana-release/bin:$PATH"
solana-keygen new -o ${SOLANA_HOME}/validator-keypair.json --no-bip39-passphrase || true
solana-sys-tuner --user ${SOLANA_USER}> ${SOLANA_HOME}/sys-tuner.log 2>&1 &

# make sure solana owns its own data dir
sudo chown -R ${SOLANA_USER}:${SOLANA_USER} ${SOLANA_HOME}
sudo -iu ${SOLANA_USER} mkdir -p ${SOLANA_HOME}/ledger

systemctl enable --now sol

# give solana-validator two chances to download at a fast enough rate,
# otherwise let it be rebuilt by AWS.
retry 2 restart_if_too_slow