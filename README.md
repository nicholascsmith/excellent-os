# excellent-os

A workstation image built with [BlueBuild](https://blue-build.org) on top of [secureblue](https://secureblue.dev)'s `sericea-main-hardened`. The image rebuilds daily and is signed. Dotfiles are installed after first boot.

## Install

1. **Install secureblue.** Follow [secureblue's install guide](https://secureblue.dev/install#iso) to install its Sway ISO (the `main` image), with Secure Boot on. Encrypt the disk and name the user `ncarters`: the image logs that user in automatically, so the disk password is the only one you type at boot. If secureblue then says its Secure Boot key is not enrolled, run `ujust enroll-secure-boot-keys`.

2. **Switch to the image.**

   ```bash
   run0 bootc switch ghcr.io/nicholascsmith/excellent-os:latest
   systemctl reboot
   ```

3. **Switch again with signature checks.** The first switch can't check signatures, because the key that checks them ships inside the image. Automatic updates stay off until this step is done.

   ```bash
   run0 bootc switch --enforce-container-sigpolicy ghcr.io/nicholascsmith/excellent-os:latest
   systemctl reboot
   ```

## First-Boot Setup

```bash
ujust excellent-setup
```

The setup asks for input a few times, and is safe to re-run. It:

1. Enables Homebrew, installs `glab` and logs in to GitLab
2. Installs the dotfiles
3. Creates a git signing key and registers it with GitLab
4. Recreates the login keyring without a password (it asks first), since autologin never unlocks it, and asks for the Context7 API key (press Enter to skip; re-run the setup to add it later)
5. Switches the login shell to zsh
6. Installs the Brewfile
7. Installs the Flatpak apps and Steam (choose the Flatpak method)

Afterwards, run `gh auth login`, then log out and back in.
