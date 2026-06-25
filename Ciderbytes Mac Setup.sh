#!/usr/bin/env zsh
# =============================================================================
# Modern macOS Setup Script (Multi-Phase Architecture)
# =============================================================================
# This script automates the setup of a new Mac with modern development tools,
# applications, and system preferences. Updated for Apple Silicon compatibility
# and modular execution.
#
# 🚀 QUICK START (Full Interactive Setup via Remote):
#   /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/Ciderbytes%20Mac%20Setup.sh)"
#
# 🛠️ REMOTE EXECUTION WITH FLAGS:
#   To pass flags without downloading the repository, pipe to `zsh -s --`:
#   curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/Ciderbytes%20Mac%20Setup.sh | zsh -s -- --verbose --brew
#
# 💻 LOCAL USAGE:
#   Full Interactive Setup: ./Ciderbytes\ Mac\ Setup.sh
#   Verbose Output:         ./Ciderbytes\ Mac\ Setup.sh --verbose
#   Run Specific Phase:     ./Ciderbytes\ Mac\ Setup.sh --system 
#   Available Phases:       --system, --brew, --security, --shell, --macos
#   Combine Flags:          ./Ciderbytes\ Mac\ Setup.sh -v --brew --macos
# =============================================================================

# =============================================================================
# USER CONFIGURATION & DEFAULTS
# =============================================================================
# Modify these variables to point to your own repository files if you fork this kit.
# These act as fallbacks if environment variables are not explicitly passed.

REPO_BREWFILE_URL=${SETUP_BREWFILE_URL:-"https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/brewfile"}
REPO_ZSHRC_URL=${SETUP_ZSHRC_URL:-"https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.zshrc"}
REPO_P10K_URL=${SETUP_P10K_URL:-"https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.p10k.zsh"}

# System Paths & Logging
LOG_FILE="$HOME/.brewmaster_setup.log"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# =============================================================================
# GLOBAL HELPERS & INITIALIZATION
# =============================================================================

# Default verbosity is off (0). Enabled via -v or --verbose
VERBOSE=0

echo "--- Brewmaster Setup Started: $(date) ---" >> "$LOG_FILE"

# Keep-alive: Update existing `sudo` time stamp until the script has finished
# This prevents the user from being prompted for their password repeatedly during long installs.
keep_sudo_alive() {
    echo -e "\n🔐 Requesting administrator privileges..."
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# UI Helper: Print clearly visible section headers and append to log
print_header() {
    echo -e "\n\033[1;34m=================================================================\033[0m"
    echo -e "\033[1;36m====> $1 \033[0m"
    echo -e "\033[1;34m=================================================================\033[0m"
    echo "[$(date +'%H:%M:%S')] PHASE: $1" >> "$LOG_FILE"
}

# UI Helper: Print granular details ONLY if verbose mode is enabled, but always log them
# Uses a dimmed gray color to differentiate from main actionable prompts.
log_verbose() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "\033[2m   ↳ $1\033[0m"
    fi
    echo "[$(date +'%H:%M:%S')] VERBOSE: $1" >> "$LOG_FILE"
}

# =============================================================================
# PHASE 1: SYSTEM PRE-REQUISITES
# =============================================================================
phase_system() {
    print_header "Phase 1: System Pre-requisites & Core Configuration"

    # 1. Full Disk Access Warning
    # Apple's SIP (System Integrity Protection) prevents terminal from altering certain 
    # system preference domains (like Safari) without explicit user permission.
    echo -e "⚠️  This script needs Terminal to have Full Disk Access."
    echo "   1. Go to System Settings > Privacy & Security > Full Disk Access."
    echo "   2. Add your Terminal app to the list and restart it."
    log_verbose "Opening System Preferences to the Privacy pane..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    read "?Press [Enter] to confirm you have granted Full Disk Access..."

    # 2. System Software Updates
    # Installs vital security data (XProtect, Malware Removal Tool) and pending macOS updates.
    if [[ -z "$SETUP_SKIP_UPDATES" ]]; then
        read "do_updates?Would you like to check for and install macOS updates and security data? [Y/n] "
        if [[ "${do_updates:-Y}" =~ ^[Yy]$ ]]; then
            echo -e "\n🔄 Updating system software and security data..."
            log_verbose "Running 'softwareupdate -i -a --include-config-data'. This may take several minutes."
            sudo softwareupdate -i -a --include-config-data 2>&1 | tee -a "$LOG_FILE"
            echo "✅ System software update completed."
        else
            echo "⏭️  Skipping system software updates."
        fi
    fi

    # 3. Rosetta 2 Installation (Apple Silicon only)
    # Rosetta 2 translates x86_64 (Intel) instructions to arm64 (Apple Silicon).
    # Some legacy background helpers and applications still require this to run.
    if [[ $(uname -m) == "arm64" ]]; then
        log_verbose "Apple Silicon detected. Checking for Rosetta 2 LaunchDaemon..."
        if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
            echo -e "\n📦 Installing Rosetta 2 for Intel app compatibility..."
            sudo softwareupdate --install-rosetta --agree-to-license 2>&1 | tee -a "$LOG_FILE"
            echo "✅ Rosetta 2 installation completed."
        else
            echo -e "\n✅ Rosetta 2 is already installed."
        fi
    fi

    # 4. Touch ID for Sudo (macOS Sonoma 14+ only)
    # Instead of typing your password for `sudo` commands, this alters the PAM 
    # (Pluggable Authentication Modules) configuration to accept your fingerprint.
    macos_major=$(sw_vers -productVersion | cut -d. -f1)
    if [[ $macos_major -ge 14 && -f /etc/pam.d/sudo_local.template ]]; then
        log_verbose "macOS 14+ detected. Editing PAM sudo_local configuration..."
        echo -e "\n🔒 Enabling Touch ID for sudo authentication..."
        sudo sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
        echo "✅ Touch ID for sudo enabled."
    fi

    # 5. Xcode Command Line Tools
    # Provides git, make, gcc, and other vital compiling libraries necessary for Homebrew.
    echo -e "\n🛠️  Checking Xcode installation..."
    if ! xcode-select -p &> /dev/null; then
        echo -e "\n📦 Installing Xcode Command Line Tools..."
        log_verbose "Triggering xcode-select --install..."
        xcode-select --install
        echo "⏳ Please complete the Xcode Command Line Tools installation in the popup window."
        read "?Press [Enter] after the installation completes..."
    else
        echo -e "\n✅ Xcode Command Line Tools already installed."
        log_verbose "Path found at: $(xcode-select -p)"
    fi
}

# =============================================================================
# PHASE 2: HOMEBREW & APPLICATIONS
# =============================================================================
phase_brew() {
    print_header "Phase 2: Package Management & Application Installation"

    # 1. Homebrew Installation & Pathing
    # Homebrew uses different default prefixes based on CPU architecture.
    # Intel: /usr/local | Apple Silicon: /opt/homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "\n🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | tee -a "$LOG_FILE"
        
        log_verbose "Mapping Homebrew PATH based on architecture..."
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            HOMEBREW_PREFIX="/opt/homebrew"
        else
            eval "$(/usr/local/bin/brew shellenv)"
            HOMEBREW_PREFIX="/usr/local"
        fi
    else
        echo -e "\n✅ Homebrew is already installed."
        HOMEBREW_PREFIX=$(brew --prefix)
        log_verbose "Existing Homebrew prefix identified at: $HOMEBREW_PREFIX"
    fi

    # 2. Core Package Manager Setup
    echo -e "\n🔄 Updating Homebrew and installed packages..."
    log_verbose "Running brew update && brew upgrade..."
    brew update && brew upgrade 2>&1 | tee -a "$LOG_FILE"
    
    echo -e "\n🏪 Installing Mac App Store command line interface..."
    echo "MAS allows installing and updating App Store apps from the command line."
    brew install mas 2>&1 | tee -a "$LOG_FILE"
    echo "✅ MAS (Mac App Store CLI) installed."

    # 3. App Store Authentication
    # To ensure MAS (Mac App Store CLI) does not fail silently, we intentionally
    # force the App Store to open so the user can visually verify their active session.
    echo -e "\n📱 \033[1;31mIMPORTANT: Please verify your App Store session before proceeding.\033[0m"
    log_verbose "Opening App Store application for visual verification..."
    open -a /System/Applications/App\ Store.app
    read "?Press [Enter] after confirming you are signed into the App Store..."

    # 4. Brewfile Sourcing and Routing
    # Defines where the script should pull the list of apps to install.
    echo -e "\n📦 Brewfile Configuration"
    echo "Choose your Brewfile source:"
    echo "1. Default hosted Brewfile (from configured repository)"
    echo "2. Local Brewfile (specify file path)"
    echo "3. Alternative hosted Brewfile (specify URL)"
    
    brewfile_choice=${SETUP_BREWFILE_CHOICE:-$(read -e "choice?Select option [1/2/3]: " && echo $REPLY)}
    
    case $brewfile_choice in
        1)
            BREWFILE_PATH="$HOME/Brewfile"
            log_verbose "Downloading from $REPO_BREWFILE_URL..."
            curl -fsSL --output "$BREWFILE_PATH" "$REPO_BREWFILE_URL"
            echo "✅ Downloaded default hosted Brewfile."
            ;;
        2)
            read "local_path?Enter the full path to your local Brewfile: "
            # Handles bash-style tilde expansion to absolute home path
            BREWFILE_PATH="${local_path/#\~/$HOME}"
            if [[ "$BREWFILE_PATH" != "$HOME/Brewfile" ]]; then
                log_verbose "Copying $BREWFILE_PATH to $HOME/Brewfile..."
                cp "$BREWFILE_PATH" "$HOME/Brewfile"
                BREWFILE_PATH="$HOME/Brewfile"
            fi
            echo "✅ Using local Brewfile."
            ;;
        3)
            read "custom_url?Enter the URL to your hosted Brewfile: "
            BREWFILE_PATH="$HOME/Brewfile"
            log_verbose "Downloading from custom URL: $custom_url..."
            curl -fsSL --output "$BREWFILE_PATH" "$custom_url"
            echo "✅ Downloaded custom hosted Brewfile."
            ;;
        *)
            echo "❌ Invalid selection. Using default hosted Brewfile"
            BREWFILE_PATH="$HOME/Brewfile"
            curl -fsSL --output "$BREWFILE_PATH" "$REPO_BREWFILE_URL"
            ;;
    esac

    # 5. Brewfile Review & Editing
    # Allows last-minute adjustments to the Brewfile before kicking off the long install process.
    if [[ -z "$SETUP_SKIP_BREWFILE_EDIT" ]]; then
        read "edit_brewfile?Would you like to review/edit the Brewfile before installation? [y/N] "
        if [[ "$edit_brewfile" =~ ^[Yy]$ ]]; then
            # Determine best available editor
            if [[ -n "$EDITOR" ]]; then
                editor="$EDITOR"
            elif command -v code &> /dev/null; then
                editor="code"
            elif command -v nano &> /dev/null; then
                editor="nano"
            else
                editor="vi"
            fi
            echo "📝 Opening Brewfile in $editor..."
            $editor "$BREWFILE_PATH"
            read "?Press [Enter] to continue with installation..."
        fi
    fi

    # 6. Brew Bundle Installation
    # Reads the Brewfile and installs all requested formulae, casks, and MAS apps.
    echo -e "\n⏳ Starting application installation process from Brewfile..."
    if brew bundle check --file="$BREWFILE_PATH"; then
        echo "✅ All Brewfile dependencies are already satisfied."
    else
        log_verbose "Executing 'brew bundle install'. This process may take 15-30 minutes."
        brew bundle install -v --file="$BREWFILE_PATH" 2>&1 | tee -a "$LOG_FILE"
        echo "✅ Application installation from Brewfile completed."
    fi

    # Fix Homebrew permissions for shell completion
    # Ensures zsh can properly tab-complete homebrew commands without security warnings.
    log_verbose "Setting proper write permissions on Homebrew share directory for zsh completion..."
    chmod -R go-w "$HOMEBREW_PREFIX/share" 2>/dev/null || true
}

# =============================================================================
# PHASE 3: SECURITY & IDENTITY (SSH/GIT)
# =============================================================================
phase_security() {
    print_header "Phase 3: Security & Git Identity"

    # 1. SSH Key Strategy Generation
    # We offer traditional file-based keys or modern 1Password SSH Agent integration.
    echo "SSH Key Management:"
    echo "1. Traditional local SSH keys (ed25519)"
    echo "2. 1Password SSH key management (Agent Integration)"
    ssh_choice=${SETUP_SSH_CHOICE:-$(read -e "ssh_default?Default SSH key management [1/2]: " && echo $REPLY)}

    if [[ "$ssh_choice" == "1" ]]; then
        ssh_email=${SETUP_GIT_EMAIL:-$(read -e "emailaddress?Enter your email address for the SSH key: " && echo $REPLY)}
        echo "🔑 Generating ed25519 SSH key pair..."
        # -q suppresses output, -N "" creates it with no passphrase (relies on macOS keychain instead)
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -q -N ""
        
        eval "$(ssh-agent -s)"
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        
        # Add macOS keychain integration so the agent loads the key automatically
        log_verbose "Writing standard SSH config to ~/.ssh/config..."
        if ! grep -q "Host \*" ~/.ssh/config 2>/dev/null; then
            cat >> ~/.ssh/config << 'EOF'
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        fi
        
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
        pbcopy < ~/.ssh/id_ed25519.pub
        echo "📋 SSH public key copied to clipboard."
        
    elif [[ "$ssh_choice" == "2" ]]; then
        echo -e "\n🔐 Configuring SSH client for 1Password SSH Agent..."
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        
        # Maps the default SSH socket directly into the 1Password application pipeline
        log_verbose "Writing 1Password IdentityAgent config to ~/.ssh/config..."
        if ! grep -q "IdentityAgent" ~/.ssh/config 2>/dev/null; then
            cat >> ~/.ssh/config << 'EOF'

# 1Password SSH Agent
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        fi
        echo "✅ Configured for 1Password SSH Agent."
    fi

    # 2. GitHub Integration Prompt
    if [[ "$ssh_choice" == "1" || "$ssh_choice" == "2" ]]; then
        echo -e "\n🌐 Opening GitHub SSH settings..."
        open "https://github.com/settings/ssh"
        if [[ "$ssh_choice" == "1" ]]; then
            echo "📎 Paste the key that was just copied to your clipboard."
        else
            echo "🔑 Use the 1Password browser extension to fill your public key."
        fi
        read "?Press [Enter] after adding the SSH key to GitHub..."
    fi

    # 3. macOS Global Gitignore
    # Prevents .DS_Store and other Apple-specific hidden files from cluttering repositories globally.
    if [[ ! -f ~/.gitignore ]]; then
        echo -e "\n📥 Downloading macOS-specific gitignore file..."
        log_verbose "Fetching from github/gitignore repository..."
        curl -fsSL https://raw.githubusercontent.com/github/gitignore/main/Global/macOS.gitignore -o ~/.gitignore
        git config --global core.excludesfile ~/.gitignore
    fi

    # 4. Global Git Configuration
    current_git_name=$(git config --global user.name)
    current_git_email=$(git config --global user.email)
    
    if [[ -z "$current_git_name" ]]; then
        git_name=${SETUP_GIT_NAME:-$(read -e "githubuser?Enter your Git user.name: " && echo $REPLY)}
    else
        git_name="$current_git_name"
    fi

    if [[ -z "$current_git_email" ]]; then
        git_email=${SETUP_GIT_EMAIL:-$(read -e "githubuseremail?Enter your Git user.email: " && echo $REPLY)}
    else
        git_email="$current_git_email"
    fi
    
    echo "📝 Applying Git configurations..."
    log_verbose "Setting username, email, main branch default, and credential helper..."
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    # Modern Git standard (main vs master)
    git config --global init.defaultBranch main
    # Normalizes line endings to prevent Windows/Mac commit conflicts
    git config --global core.autocrlf input
    # Prevents merge commits on simple pulls
    git config --global pull.rebase false
    # Uses native macOS keychain to store HTTP git passwords
    git config --global credential.helper osxkeychain
    git config --global core.editor "code --wait"
}

# =============================================================================
# PHASE 4: SHELL & TERMINAL
# =============================================================================
phase_shell() {
    print_header "Phase 4: Shell Architecture & Terminal Utilities"

    # 1. Oh My Zsh Installation
    if [[ ! -d ~/.oh-my-zsh ]]; then
        echo -e "\n📦 Installing Oh My Zsh framework..."
        # RUNZSH=no prevents the installer from automatically switching the active shell,
        # which would halt the execution of the rest of this setup script.
        log_verbose "Running OMZ install script with RUNZSH=no..."
        RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1 | tee -a "$LOG_FILE"
    else
        echo -e "\n✅ Oh My Zsh is already installed."
    fi

    # 2. Shell Configuration & Theming
    echo "📝 Installing custom .zshrc and Powerlevel10k configuration..."
    # Backup existing configuration to prevent accidental data loss
    [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d_%H%M%S)
    
    log_verbose "Downloading .zshrc and .p10k.zsh from configured repository..."
    curl -fsSL "$REPO_ZSHRC_URL" > ~/.zshrc
    curl -fsSL "$REPO_P10K_URL" > ~/.p10k.zsh

    # 3. Zsh Plugins
    echo -e "\n🔌 Sourcing custom Zsh plugins..."
    
    # Install zsh-autosuggestions: Uses shell history to suggest completions as you type
    log_verbose "Checking zsh-autosuggestions..."
    [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" -q
    
    # Install zsh-syntax-highlighting: Highlights valid vs invalid commands in red/green
    log_verbose "Checking zsh-syntax-highlighting..."
    [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" -q
    
    # Install z: Learns your cd history so you can jump to directories by name
    log_verbose "Checking z directory jumper..."
    [[ ! -d "$ZSH_CUSTOM_DIR/plugins/z" ]] && git clone https://github.com/rupa/z.git "$ZSH_CUSTOM_DIR/plugins/z" -q
    
    # Update all custom plugins to latest versions
    echo "🔄 Updating all custom plugins..."
    for plugin in "$ZSH_CUSTOM_DIR"/plugins/*/; do
        if [[ -d "$plugin/.git" ]]; then
            plugin_name=$(basename "$plugin")
            log_verbose "Git pulling latest for $plugin_name..."
            git -C "$plugin" pull -q
        fi
    done

    # 4. Universal Version Manager (mise)
    # Replaces individual managers like nvm, pyenv, rbenv, etc., with a single rust-based binary
    echo -e "\n📦 Setting up 'mise' (Universal Version Manager)..."
    if ! command -v mise &> /dev/null; then
        log_verbose "Installing mise via Homebrew..."
        brew install mise 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Ensure mise initializes cleanly in our zshrc
    if ! grep -q 'mise activate zsh' ~/.zshrc 2>/dev/null; then
        log_verbose "Injecting mise initialization string into ~/.zshrc..."
        cat >> ~/.zshrc << 'EOF'

# Initialize mise (Universal Version Manager)
eval "$(mise activate zsh)"
EOF
        echo "✅ mise configured in shell profile."
    else
        echo "✅ mise is already configured in shell profile."
    fi

    # 5. Visual Studio Code Path Integration
    echo -e "\n💻 Configuring Visual Studio Code..."

    # Add VS Code 'code' command to PATH so you can type `code .` to open a directory
    if ! grep -q "Visual Studio Code" ~/.zshrc 2>/dev/null; then
        echo -e "\n💻 Adding Visual Studio Code CLI to PATH..."
        log_verbose "Injecting VS Code binary path into ~/.zshrc..."
        cat >> ~/.zshrc << 'EOF'

# Add Visual Studio Code (code) command to PATH
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
EOF
        echo "✅ VS Code command line tool configured"
    fi

    # 6. Mackup Restore (DEPRECATED: Legacy Application Settings - will be removed in future versions)
    # Mackup syncs application preferences via iCloud. It is heavily broken on macOS 14+.
    macos_major=$(sw_vers -productVersion | cut -d. -f1)
    if [[ $macos_major -lt 14 ]]; then
        echo -e "\n💾 Mackup Configuration Restore"
        read "do_mackup?Restore application settings from Mackup? [y/N] "
        if [[ "$do_mackup" =~ ^[Yy]$ ]]; then
            echo "☁️ Please ensure Mackup folder is downloaded from iCloud."
            open ~/Library/Mobile\ Documents/com~apple~CloudDocs/
            read "?Press [Enter] after confirming Mackup folder is available locally..."
            
            mackup_config="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Mackup/.mackup.cfg"
            if [[ -f "$mackup_config" ]]; then
                log_verbose "Linking $mackup_config to home directory..."
                ln -sf "$mackup_config" ~/.mackup.cfg
                mackup restore 2>&1 | tee -a "$LOG_FILE"
                echo "✅ Mackup restore completed."
            fi
        fi
    fi
}

# =============================================================================
# PHASE 5: MACOS PREFERENCES
# =============================================================================
phase_macos() {
    print_header "Phase 5: macOS System & Development Preferences"

    # 1. Finder Preferences
    echo "📁 Configuring Finder..."

    # Enable text selection in Quick Look previews
    defaults write com.apple.finder QLEnableTextSelection -bool true
    # Set Finder to use column view by default (better for development)
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
    # Set new Finder windows to open in home directory
    defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME"
    # Disable file extension change warnings (useful for development)
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    # 2. Dock Preferences
    echo "🚢 Configuring Dock..."
    
    # Enable Dock auto-hide for more screen space
    defaults write com.apple.dock autohide -bool true
    # Remove auto-hide delay for instant appearance
    defaults write com.apple.dock autohide-delay -float 0
    # Speed up auto-hide animation
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    # Position Dock on the left side for more vertical space
    defaults write com.apple.dock orientation -string "left"
    
    # 3. Screenshot Preferences
    echo "📸 Configuring Screenshots..."
    
    # Create Screenshots folder on Desktop
    mkdir -p ~/Desktop/Screenshots
    # Set screenshot save location to Screenshots folder
    defaults write com.apple.screencapture location ~/Desktop/Screenshots
    # Set screenshot format to PNG (better quality than JPEG)
    defaults write com.apple.screencapture type -string "png"
    
    # 4. Safari Developer Preferences
    echo "🌐 Configuring Safari for development..."

    # Enable Safari's internal debug menu
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    # Enable Safari's Develop menu
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    # Enable Web Inspector in Safari
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
    # Allow hitting the Backspace key to go to the previous page in history
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
    
    # 5. Chrome Preferences
    echo "🌐 Configuring Chrome..."

    # Disable annoying backswipe navigation in Chrome
    defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
    
    # 6. Apply Changes
    echo "🔄 Restarting affected system UI processes..."
    log_verbose "Killing Finder, Dock, and SystemUIServer to apply 'defaults' changes..."
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
    
    echo "🧹 Cleaning up Homebrew caches..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"
}

# =============================================================================
# ORCHESTRATOR / EXECUTION CONTROLLER
# =============================================================================

# State variables to track which phases to run
RUN_SYSTEM=0
RUN_BREW=0
RUN_SECURITY=0
RUN_SHELL=0
RUN_MACOS=0
RUN_ALL=1

# Parse CLI Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=1 ;;
        --system)     RUN_SYSTEM=1; RUN_ALL=0 ;;
        --brew)       RUN_BREW=1; RUN_ALL=0 ;;
        --security)   RUN_SECURITY=1; RUN_ALL=0 ;;
        --shell)      RUN_SHELL=1; RUN_ALL=0 ;;
        --macos)      RUN_MACOS=1; RUN_ALL=0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Execute Based on Flags
keep_sudo_alive

if [[ $RUN_ALL -eq 1 || $RUN_SYSTEM -eq 1 ]]; then phase_system; fi
if [[ $RUN_ALL -eq 1 || $RUN_BREW -eq 1 ]]; then phase_brew; fi
if [[ $RUN_ALL -eq 1 || $RUN_SECURITY -eq 1 ]]; then phase_security; fi
if [[ $RUN_ALL -eq 1 || $RUN_SHELL -eq 1 ]]; then phase_shell; fi
if [[ $RUN_ALL -eq 1 || $RUN_MACOS -eq 1 ]]; then phase_macos; fi

# =============================================================================
# COMPLETION MESSAGE AND NEXT STEPS
# =============================================================================
echo -e "\n🎉 \033[1;32m═══════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;32m✅ macOS setup completed successfully!\033[0m"
echo -e "\033[1;32m═══════════════════════════════════════════════════════\033[0m"

echo -e "\n📋 \033[1;33mRecommended next steps:\033[0m"
echo -e "\033[1;36m1.\033[0m 🔄 Restart your computer to ensure all changes take effect."
echo -e "\033[1;36m2.\033[0m 🐚 Open a new terminal and run: \033[1;31momz update\033[0m"
echo -e "\033[1;36m3.\033[0m 🎨 Configure iTerm2/Terminal font to 'MesloLGS NF' for proper theme display."
echo -e "\033[1;36m4.\033[0m 💻 Set VS Code terminal font to 'MesloLGS NF' in settings."
echo -e "\033[1;36m5.\033[0m ⚡ Run \033[1;31mp10k configure\033[0m to customize your terminal theme."
echo -e "\n📑 \033[1;34mExecution log saved to:\033[0m $LOG_FILE"

echo -e "\n🎯 \033[1;33mYour modular development environment is now ready!\033[0m"

echo "--- Brewmaster Setup Completed: $(date) ---" >> "$LOG_FILE"

# Start a new zsh session to load all configurations
echo -e "\n🚀 Starting new shell session with updated configuration..."
exec zsh