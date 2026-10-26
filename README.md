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

secureblue's kernel is signed with its own key, so enroll that key before switching while Secure Boot is on. Otherwise shim refuses to boot the new image:

```bash
curl -fLO https://github.com/secureblue/secureblue/raw/live/files/system/usr/share/pki/akmods/certs/akmods-secureblue.der
run0 mokutil --import akmods-secureblue.der
systemctl reboot
```

Use the password `secureblue`, then choose **Enroll MOK** in MokManager during the reboot.

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

## After First Boot

```bash
ujust excellent-setup
```

It logs in to GitLab over HTTPS, installs the `ncarters/excellent` dotfiles, creates a git signing key and registers it with GitLab, switches the shell to zsh, installs the Brewfile and pyrefly, adds the unfiltered Flathub remote, installs the Flatpak apps, and runs `ujust install-steam` (choose the Flatpak method). It skips finished steps, so it is safe to re-run. The recipe lives in `files/justfiles/excellent.just`.

## Updates

The image follows secureblue's `latest` tag, so it moves to new Fedora releases when secureblue does. It rebuilds daily, and a failed scheduled build opens a GitHub issue.

The system updates itself in the background. secureblue's provenance check only accepts secureblue's own images, so the image replaces `/usr/libexec/secureblue/verify-provenance.sh` with a check that allows updates only while the signed `bootc switch` is in effect. rpm-ostree then rejects any image whose cosign signature fails. This covers automatic updates, upgrade-on-boot and `ujust update-system`.

## Hardening Defaults

The image changes a few secureblue defaults on purpose:

- Xwayland is enabled for Steam and Windows games.
- Brave Origin Beta keeps its setuid `chrome-sandbox` helper. secureblue strips setuid binaries from its own image, but Brave needs this helper to sandbox sites while secureblue blocks unprivileged user namespaces.
- Brave, Claude Code, Ghostty and SwayFX come from their vendors' or COPR repos, which are removed again after the build.
- Proton VPN's split-tunnelling service stays enabled for future use.

Other defaults are unchanged; enable a toggle only when its symptom appears.

| Symptom | Toggle |
| --- | --- |
| Bluetooth does not work | `ujust set-bluetooth-modules on` |
| Podman or Distrobox cannot start containers | `ujust set-container-userns on` |
| An Electron or Chromium app, such as Brave, crashes with a memory allocator error | `with-standard-malloc <command>` |
| An app needs ptrace | `ujust set-ptrace` |
| Printing is needed | `ujust set-cups on` |
| Homebrew is unavailable | `ujust set-brew on` |
