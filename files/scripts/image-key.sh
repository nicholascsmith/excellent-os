#!/usr/bin/env bash
set -euo pipefail

# Runs after the signing module. /usr/share is read-only on the booted system, so nothing in /etc can remove the key that updates depend on.
image=ghcr.io/nicholascsmith/excellent-os
key=/usr/share/pki/containers/excellent-os.pub
policy=/etc/containers/policy.json

mkdir -p "$(dirname "$key")"
mv /etc/pki/containers/excellent-os.pub "$key"
chmod 0644 "$key"

jq --arg image "$image" --arg key "$key" \
	'.transports.docker[$image][0].keyPath = $key' "$policy" >/tmp/policy.json
mv /tmp/policy.json "$policy"
