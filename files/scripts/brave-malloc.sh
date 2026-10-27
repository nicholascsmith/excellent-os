#!/usr/bin/env bash
# Brave aborts under secureblue's hardened_malloc. Replacing its command with a wrapper covers every way it starts:
# the launcher, the keybind, and links opened by other programs such as glab and gh.
set -euo pipefail

command=/usr/bin/brave-origin-beta
target="$(readlink -f "$command")"
# The package's launch script finds Brave next to itself, so it must stay where it is and the command must be a link to it
[[ "$target" != "$command" ]]

rm "$command"
printf '#!/usr/bin/bash\nexec /usr/bin/with-standard-malloc %s "$@"\n' "$target" >"$command"
chmod 755 "$command"
