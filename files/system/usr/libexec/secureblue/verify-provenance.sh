#!/usr/bin/bash
# Replaces secureblue's provenance check, which only accepts ghcr.io/secureblue images and would
# block every update of this image. Updates are allowed only while the booted deployment enforces
# the image's cosign signature policy, so rpm-ostree refuses any image whose signature fails.
set -euo pipefail

image_ref=$(rpm-ostree status --booted --json | jq -cr '.deployments[0]."container-image-reference"')

case "${image_ref}" in
    ostree-image-signed:docker://ghcr.io/nicholascsmith/excellent-os:*)
        echo "Signature policy enforced for ${image_ref#*docker://}"
        ;;
    *)
        echo "WARNING: '${image_ref}' does not enforce the excellent-os signature policy." >&2
        echo "Run: run0 bootc switch --enforce-container-sigpolicy ghcr.io/nicholascsmith/excellent-os:latest" >&2
        exit 1
        ;;
esac
