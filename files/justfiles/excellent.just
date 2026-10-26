# Set up dotfiles, zsh, Homebrew, Flatpaks and Steam after first boot; safe to re-run
excellent-setup:
    #!/usr/bin/bash
    set -euo pipefail

    glab auth status >/dev/null 2>&1 || glab auth login
    /usr/libexec/excellent/install-dotfiles

    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]]; then
        run0 usermod -s /usr/bin/zsh "$USER"
    fi

    ujust set-brew on
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    brew bundle --file=/usr/share/excellent/Brewfile

    uv tool list | grep -q '^pyrefly ' || uv tool install pyrefly

    pi_extension="$HOME/.agents/mcp/pi-extension"
    if [[ -f "$pi_extension/package-lock.json" && ! -d "$pi_extension/node_modules" ]]; then
        npm ci --prefix "$pi_extension"
    fi

    ujust set-flathub-unfiltered on
    flatpak install --user --or-update -y --noninteractive flathub \
        com.heroicgameslauncher.hgl \
        com.obsproject.Studio \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        org.signal.Signal

    # Choose the Flatpak method when asked
    flatpak info com.valvesoftware.Steam >/dev/null 2>&1 || ujust install-steam

    echo "Setup complete. Log out and back in to start using zsh."
