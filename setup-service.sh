#!/usr/bin/bash

set -e

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
