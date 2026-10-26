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
ujust excellent-setup
```

It logs in to GitLab, installs the `ncarters/excellent` dotfiles, switches the shell to zsh, installs the Brewfile and pyrefly, adds the unfiltered Flathub remote, installs the Flatpak apps, and runs `ujust install-steam` (choose the Flatpak method). It skips finished steps, so it is safe to re-run. The recipe lives in `files/justfiles/excellent.just`.

## Updates

The image rebuilds daily and the system updates itself in the background. secureblue's provenance check only recognises secureblue's own images, so the image removes it from the automatic update services and relies on the signature policy enforced by the signed `bootc switch` instead.

## Hardening Defaults

The image enables Xwayland for Steam and Windows games. Other secureblue defaults are left unchanged; enable a toggle only when its symptom appears.

| Symptom | Toggle |
| --- | --- |
| Bluetooth does not work | `ujust set-bluetooth-modules on` |
| Podman or Distrobox cannot start containers | `ujust set-container-userns on` |
| An Electron or Chromium app, such as Brave, crashes with a memory allocator error | `with-standard-malloc <command>` |
| An app needs ptrace | `ujust set-ptrace` |
| Printing is needed | `ujust set-cups on` |
| Homebrew is unavailable | `ujust set-brew on` |
