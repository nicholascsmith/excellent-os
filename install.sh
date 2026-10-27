#!/usr/bin/env bash
# Switches a fresh secureblue install to excellent-os. secureblue rejects images signed by keys it
# doesn't know, so this trusts the image's key just long enough to pull it, then puts the policy back
# so the image's own policy takes over after the reboot. Run as root.
set -euo pipefail

image=ghcr.io/nicholascsmith/excellent-os
key=/etc/pki/containers/excellent-os.pub
registry=/etc/containers/registries.d/excellent-os.yaml
policy=/etc/containers/policy.json
policy_tmp=$(mktemp)

restore() {
	cp /usr/etc/containers/policy.json "$policy"
	rm -f "$key" "$registry" "$policy_tmp"
}
trap restore EXIT

mkdir -p /etc/pki/containers
curl -fsSLo "$key" https://raw.githubusercontent.com/nicholascsmith/excellent-os/master/cosign.pub
jq --arg image "$image" --arg key "$key" \
	'.transports.docker |= {($image): [{type: "sigstoreSigned", keyPath: $key, signedIdentity: {type: "matchRepository"}}]} + .' \
	/usr/etc/containers/policy.json >"$policy_tmp"
cp "$policy_tmp" "$policy"
printf 'docker:\n  %s:\n    use-sigstore-attachments: true\n' "$image" >"$registry"

bootc switch --enforce-container-sigpolicy "$image:latest"
echo "Done. Run: systemctl reboot"
