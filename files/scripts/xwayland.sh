#!/usr/bin/env bash
set -euo pipefail

# secureblue turns Xwayland off for GNOME with this override; X11-only apps need it
rm -f /etc/systemd/user/org.gnome.Shell@user.service.d/override.conf
