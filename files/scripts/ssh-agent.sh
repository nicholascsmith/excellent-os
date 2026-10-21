#!/usr/bin/env bash
set -euo pipefail

systemctl --global enable gcr-ssh-agent.socket
