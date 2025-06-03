# Brewmaster-Kit

A modern, interactive macOS setup script for Mac developers, admins, and power users.
**Automate your Mac’s configuration, development environment, and essential apps with one command.**

## Why This Tool Exists

As a field tech and power user, I often find myself needing to get a brand new, untouched Mac up and running—sometimes with nothing but an internet connection and no access to imaging or configuration management tools. I prefer to start every machine fresh, without restoring from backups or migrating old data, to ensure each setup is clean, performant, and free of clutter.

This tool isn’t meant for mass-imaging or provisioning computers for end users. Instead, it’s designed for Mac admins, developers, and power users who want to quickly bootstrap a machine with their own preferred apps, settings, and customizations—without the bloat or unpredictability of a migration. The script is interactive and flexible: it knows my defaults, but lets me review and adjust my environment on every run. All software is installed from source or official repositories, so all you need is a terminal and an internet connection. Run it locally with a single curl command, and enjoy a reproducible, personalized, and up-to-date Mac setup—every time.

---

## Features

- **Interactive Setup:** Choose your Brewfile source, SSH key management, and more.
- **Apple Silicon \& Intel Support:** Handles Rosetta 2 and Homebrew location automatically.
- **Homebrew \& MAS Automation:** Installs all your Homebrew formulae, casks, and Mac App Store apps (via `mas`).
- **System Preferences Tweaks:** Configures Finder, Dock, Safari, Chrome, screenshots, and more for developer productivity.
- **SSH Key Management:** Supports both traditional SSH keys and 1Password SSH agent integration.
- **Oh My Zsh \& Plugins:** Installs Oh My Zsh, custom `.zshrc`, Powerlevel10k, and popular Zsh plugins.
- **Xcode \& Command Line Tools:** Installs and configures Xcode for Apple development.
- **Touch ID for sudo:** Enables Touch ID authentication for sudo on Sonoma and later.
- **Automatic Full Disk Access Reminder:** Prompts you to grant Terminal Full Disk Access for system tweaks.
- **Optional Mackup Restore:** Legacy support for restoring app settings (pre-Sonoma).
- **Safe, Idempotent, and User-Friendly:** Prompts before overwriting or installing, and summarizes actions.

---

## Quick Start

1. **Grant Terminal Full Disk Access**
   Go to `System Settings > Privacy & Security > Full Disk Access`, add your Terminal app, and restart Terminal.
2. **Run the Script**

```zsh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/Ciderbytes%20Mac%20Setup.sh)"
```

3. **Follow the Prompts**
   - Choose your Brewfile source (default, local, or custom URL)
   - Select SSH key management (traditional or 1Password)
   - Review and edit your Brewfile before installation (optional)
   - Sign in to the Mac App Store when prompted
   - Confirm or update your Git identity
   - Watch your Mac configure itself!

---

## What Gets Installed

- **Homebrew** and all formulae/casks from your Brewfile
- **Mac App Store apps** listed in your Brewfile (requires MAS and App Store sign-in)
- **Xcode** and Command Line Tools (if not already installed)
- **Oh My Zsh**, Powerlevel10k theme, and plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `z`, `zsh-nvm`)
- **VS Code** (with CLI integration)
- **System settings** optimized for development

---

## Key Customizations

- **Brewfile Source:**
  Use the default, a local file, or a custom URL.
- **SSH Key Management:**
  Choose between traditional keys or 1Password SSH agent.
- **Edit Brewfile Before Install:**
  Review and tweak your app list before installation.
- **Touch ID for sudo:**
  Automatically enabled on Sonoma and later.

---

## After Running the Script

- **Restart your Mac** to ensure all changes take effect.
- **Open a new terminal** and run `omz update` to update Oh My Zsh.
- **Set your terminal font** to `MesloLGS NF` for best Powerlevel10k experience.
- **Customize your prompt** with `p10k configure` if desired.

---

## Troubleshooting

- **Full Disk Access:**
  If Safari or system tweaks fail, ensure Terminal has Full Disk Access and restart it.
- **MAS Apps in VMs:**
  Mac App Store installs do not work in macOS VMs due to Apple restrictions.
- **Repeated Password Prompts:**
  Homebrew cask installs may prompt for your password multiple times; this is normal on recent macOS.
- **gcloud Python Error:**
  If you see `ModuleNotFoundError: No module named 'imp'`, temporarily use Python 3.11 to update gcloud.

---

## FAQ

**Q: Can I re-run the script safely?**
A: Yes! The script is idempotent and will not overwrite existing config without prompting.

**Q: How do I update cask or MAS apps later?**
A:

- For Homebrew casks: `brew upgrade --cask`
- For MAS apps: `mas upgrade`

**Q: Can I use my own Brewfile?**
A: Yes! Choose the local or custom URL option at the start.

---

## Contributing

Pull requests and suggestions are welcome!
Please file issues for bugs or feature requests.

**Enjoy your automated, modern Mac setup!**
