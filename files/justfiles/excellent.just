# Set up dotfiles, zsh, Homebrew, Flatpaks and Steam after first boot; safe to re-run
excellent-setup:
    #!/usr/bin/bash
    set -euo pipefail

    # glab and chezmoi come from Homebrew and are needed before the rest of the Brewfile
    ujust set-brew on
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew install glab chezmoi

    # secureblue's first password login locked this keyring with the login password, which autologin never types.
    # Encrypted keyrings start with "GnomeKeyring"; a passwordless one is plain text, so re-runs skip this.
    # This runs before the GitLab login, because glab stores its token in this keyring.
    keyrings="$HOME/.local/share/keyrings"
    if [[ -f "$keyrings/login.keyring" && "$(head -c 12 "$keyrings/login.keyring")" == GnomeKeyring ]]; then
        read -rp "Replace the password-locked login keyring with one that has no password? It is empty on a fresh install. [y/N] " answer
        if [[ "$answer" == [yY]* ]]; then
            rm "$keyrings/login.keyring"
        fi
    fi
    # A passwordless keyring is stored as plain text and never locks; the encrypted disk protects it
    if [[ ! -f "$keyrings/login.keyring" ]]; then
        install -d -m 700 "$keyrings"
        printf '[keyring]\ndisplay-name=Login\nctime=0\nmtime=0\nlock-on-idle=false\nlock-after=false\n' >"$keyrings/login.keyring"
        chmod 600 "$keyrings/login.keyring"
        echo login >"$keyrings/default"
        pkill -x -u "$USER" gnome-keyring-d || true
    fi

    # HTTPS with glab as the credential helper, because a fresh machine has no SSH key at GitLab
    if ! glab auth status --hostname gitlab.com >/dev/null 2>&1; then
        glab auth login --hostname gitlab.com --web --git-protocol https --setup-git-credential-helper
    fi
    glab config set git_protocol https --host gitlab.com
    # glab records its versioned Cellar path as the helper, which `brew cleanup` deletes after an upgrade
    git config --global --replace-all credential.https://gitlab.com.helper ''
    git config --global --add credential.https://gitlab.com.helper '!/home/linuxbrew/.linuxbrew/bin/glab auth git-credential'

    # chezmoi manages the dotfiles from this clone and asks before overwriting files changed since its last apply
    dotfiles="$HOME/Projects/excellent"
    if [[ ! -d "$dotfiles/.git" ]]; then
        chezmoi init --source "$dotfiles" https://gitlab.com/ncarters/excellent.git
    fi
    chezmoi apply

    # The dotfiles' git config signs every commit with this key
    signing_key="$HOME/.ssh/id_ed25519_git_signing"
    email="$(git config user.email)"
    if [[ ! -f "$signing_key" ]]; then
        install -d -m 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$email git signing" -f "$signing_key"
    fi
    public_key="$(cut -d' ' -f1,2 "$signing_key.pub")"
    gitlab_keys="$(glab ssh-key list)"
    if [[ "$gitlab_keys" != *"${public_key#* }"* ]]; then
        glab ssh-key add "$signing_key.pub" --title "$(hostname) git signing" --usage-type signing
    fi
    allowed_signers="$HOME/.config/git/allowed_signers"
    if ! grep -qsF "$public_key" "$allowed_signers"; then
        printf '%s namespaces="git" %s\n' "$email" "$public_key" >>"$allowed_signers"
    fi

    # The agents' Context7 MCP server reads this key; re-run the setup to add it later
    if ! secret-tool lookup service CONTEXT7_API_KEY account "$USER" >/dev/null 2>&1; then
        read -rsp "Context7 API key (Enter to skip): " context7_api_key
        echo
        if [[ -n "$context7_api_key" ]]; then
            printf '%s' "$context7_api_key" | secret-tool store --label='Context7 API key' service CONTEXT7_API_KEY account "$USER"
        fi
        unset context7_api_key
    fi

    # secureblue's terminal banner misreads this image's tag and warns in every new terminal
    mkdir -p "$HOME/.config"
    touch "$HOME/.config/no-show-user-motd"

    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
        run0 -i usermod -s /usr/bin/zsh "$USER"
    fi

    brew bundle --file=/usr/share/excellent/Brewfile

    ujust set-flathub-unfiltered on
    flatpak install --user --or-update -y --noninteractive flathub \
        com.heroicgameslauncher.hgl \
        com.obsproject.Studio \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        org.signal.Signal \
        com.valvesoftware.Steam

    # Games crash with hardened_malloc, so turn it off for both launchers, as secureblue's Steam recipe does
    flatpak override --user --unset-env=LD_PRELOAD --nofilesystem=host-os com.heroicgameslauncher.hgl
    flatpak override --user --unset-env=LD_PRELOAD --nofilesystem=host-os com.valvesoftware.Steam
    # The rest of secureblue's Steam recipe, which this image doesn't ship: the permissions Steam needs and 32-bit support
    flatpak override --user --share=network --share=ipc --socket=x11 --socket=pulseaudio --allow=multiarch --allow=per-app-dev-shm com.valvesoftware.Steam
    if rpm-ostree kargs | grep -q 'ia32_emulation=0'; then
        rpm-ostree kargs --delete-if-present=ia32_emulation=0
        echo "Reboot before running Steam."
    fi

    echo "Setup complete. Log out and back in to start using zsh."
