#!/usr/bin/env bash
set -euo pipefail

# Uses secureblue's own disabled Proton repo, which pins the signing key and checks signed metadata.
# proton-vpn-daemon's %posttrans starts its service, which fails without a running systemd.
SYSTEMD_OFFLINE=1 dnf -y install --enablerepo=protonvpn-fedora-stable --setopt=install_weak_deps=False proton-vpn-cli
