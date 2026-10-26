# Set up dotfiles, zsh, Homebrew, Flatpaks and Steam after first boot; safe to re-run
excellent-setup:
    #!/usr/bin/bash
    set -euo pipefail

    # HTTPS with glab as the credential helper, because a fresh machine has no SSH key at GitLab
    if ! glab auth status --hostname gitlab.com >/dev/null 2>&1; then
        glab auth login --hostname gitlab.com --git-protocol https --setup-git-credential-helper
    fi
    glab config set git_protocol https --host gitlab.com
    /usr/libexec/excellent/install-dotfiles

    # The dotfiles' git config signs every commit with this key
    signing_key="$HOME/.ssh/id_ed25519_git_signing"
    email="$(git config --global user.email)"
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

    # secureblue's terminal banner misreads this image's tag and warns in every new terminal
    mkdir -p "$HOME/.config"
    touch "$HOME/.config/no-show-user-motd"

    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
        run0 usermod -s /usr/bin/zsh "$USER"
    fi

    ujust set-brew on
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew bundle --file=/usr/share/excellent/Brewfile

    uv_tools="$(uv tool list)"
    [[ "$uv_tools" == *pyrefly* ]] || uv tool install pyrefly

    ujust set-flathub-unfiltered on
    flatpak install --user --or-update -y --noninteractive flathub \
        com.heroicgameslauncher.hgl \
        com.obsproject.Studio \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        org.signal.Signal

    # Games crash with hardened_malloc; same override secureblue applies to Steam
    flatpak override --user --unset-env=LD_PRELOAD --nofilesystem=host-os com.heroicgameslauncher.hgl

    # Choose the Flatpak method when asked
    flatpak info com.valvesoftware.Steam >/dev/null 2>&1 || ujust install-steam

    echo "Setup complete. Log out and back in to start using zsh."
