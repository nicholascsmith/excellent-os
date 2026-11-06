#!/usr/bin/env bash
set -euo pipefail

# Runs after the signing module, which writes to /etc. Fedora 45 keeps the container defaults in
# /usr/share, so this adds the image there and removes the /etc policy that would otherwise replace
# secureblue's. /usr/share is read-only on the booted system, so nothing in /etc can block updates.
image=ghcr.io/nicholascsmith/excellent-os
key=/usr/share/pki/containers/excellent-os.pub
policy=/usr/share/containers/policy.json
registry=nicholascsmith-excellent-os.yaml

mkdir -p "$(dirname "$key")"
mv /etc/pki/containers/excellent-os.pub "$key"
chmod 0644 "$key"

jq --arg image "$image" --arg key "$key" \
	'.transports.docker |= {($image): [{type: "sigstoreSigned", keyPath: $key, signedIdentity: {type: "matchRepository"}}]} + .' \
	"$policy" >/tmp/policy.json
mv /tmp/policy.json "$policy"
rm /etc/containers/policy.json

mv "/etc/containers/registries.d/$registry" "/usr/share/containers/registries.d/$registry"
