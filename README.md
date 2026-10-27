# excellent-os

A workstation image built with [BlueBuild](https://blue-build.org) on top of [secureblue](https://secureblue.dev)'s `sericea-main-hardened`. The image rebuilds daily and is signed. Dotfiles are installed after first boot.

## Install

1. **Install secureblue.** Follow [secureblue's install guide](https://secureblue.dev/install#iso) to install its Sway ISO (the `main` image), with Secure Boot on. Encrypt the disk, name the user `ncarters` and make it an administrator: the image logs that user in automatically, so the disk password is the only one you type at boot.

2. **Enroll secureblue's Secure Boot key.** On the first boot, a blue MOK screen appears: choose **Enroll MOK → Continue → Yes** and type `secureblue`. If it never appears, run `ujust enroll-secureblue-secure-boot-key` and reboot.

3. **Switch to the image.** secureblue rejects images signed by keys it doesn't know, so the script trusts this image's key just long enough to switch to it with signature checks on.

   ```bash
   run0
   curl -fsSL https://raw.githubusercontent.com/nicholascsmith/excellent-os/master/install.sh | bash
   systemctl reboot
   ```

## First-Boot Setup

```bash
ujust excellent-setup
```

The setup asks for input a few times, and is safe to re-run. It:

1. Enables Homebrew and installs `glab` and `chezmoi`
2. Recreates the login keyring without a password (it asks first), since autologin never unlocks it
3. Logs in to GitLab: enter the code it shows at gitlab.com on your phone or another computer
4. Installs the dotfiles
5. Creates a git signing key and registers it with GitLab
6. Asks for the Context7 API key (press Enter to skip; re-run the setup to add it later)
7. Switches the login shell to zsh
8. Installs the Brewfile
9. Installs the Flatpak apps, including Brave and Steam
10. Logs in to GitHub in Brave and registers the signing key there too

Afterwards, log out and back in.
