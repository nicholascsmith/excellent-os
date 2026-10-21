#!/usr/bin/env bash
set -euo pipefail

# proton-vpn-daemon's %posttrans starts its service, which fails without a running systemd
SYSTEMD_OFFLINE=1 dnf -y install --setopt=install_weak_deps=False proton-vpn-cli
