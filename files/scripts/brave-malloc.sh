#!/usr/bin/env bash
# Brave aborts under secureblue's hardened_malloc, so its launcher runs it with the standard allocator
set -euo pipefail

desktop=/usr/share/applications/brave-origin-beta.desktop
sed -Ei 's#^Exec=(/usr/bin/)?brave-origin-beta#Exec=/usr/bin/with-standard-malloc /usr/bin/brave-origin-beta#' "$desktop"
grep -q '^Exec=/usr/bin/with-standard-malloc' "$desktop"
