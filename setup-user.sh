#!/usr/bin/bash

set -e

# Create RPC User
adduser --disabled-password --gecos "" --home "${SOLANA_HOME}" "${SOLANA_USER}"
