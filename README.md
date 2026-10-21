# excellent-os

A Sway workstation image built with [BlueBuild](https://blue-build.org) on top of [secureblue](https://secureblue.dev)'s `sericea-main-hardened`. Dotfiles stay in the private `ncarters/excellent` repository and are installed after first boot.

## Build Setup

1. Create the GitHub repository `nicholascsmith/excellent-os` and push this directory.
2. Generate a signing key pair and keep the private key out of the repository:

   ```bash
   cosign generate-key-pair
   ```

3. Add the private key as the repository secret `SIGNING_SECRET`, and commit `cosign.pub` to the repository root.
4. Make the `excellent-os` package public in GitHub Packages after the first build so the machine can pull it.

## Install

From an existing secureblue or Fedora Atomic install, switch to the unsigned image first:

```bash
run0 bootc switch ghcr.io/nicholascsmith/excellent-os:latest
systemctl reboot
```

After the reboot, switch to the signed image:

```bash
run0 bootc switch --enforce-container-sigpolicy ghcr.io/nicholascsmith/excellent-os:latest
systemctl reboot
```

Enroll the secureblue Secure Boot key if prompted:

```bash
ujust enroll-secureblue-secure-boot-key
```

## After First Boot

```bash
glab auth login
/usr/libexec/excellent/install-dotfiles
run0 usermod -s /usr/bin/zsh "$USER"
brew bundle --file=/usr/share/excellent/Brewfile
uv tool install pyrefly
curl -f https://zed.dev/install.sh | sh
ujust set-flathub-unfiltered on
flatpak install --user flathub com.brave.Browser com.heroicgameslauncher.hgl com.obsproject.Studio org.inkscape.Inkscape org.kde.kdenlive org.signal.Signal
ujust install-steam
```

The unfiltered Flathub remote is per user, so it is added after first boot rather than in the image. `ujust install-steam` installs the Steam Flatpak with the overrides and kernel argument it needs; choose the Flatpak method.

## Hardening Defaults

The image enables Xwayland for Steam and Windows games. Other secureblue defaults are left unchanged; enable a toggle only when its symptom appears.

| Symptom | Toggle |
| --- | --- |
| Bluetooth does not work | `ujust set-bluetooth-modules on` |
| Podman or Distrobox cannot start containers | `ujust set-container-userns on` |
| An Electron app crashes with a memory allocator error | `with-standard-malloc <command>` |
| An app needs ptrace | `ujust set-ptrace` |
| Printing is needed | `ujust set-cups on` |
| Homebrew is unavailable | `ujust set-brew on` |
