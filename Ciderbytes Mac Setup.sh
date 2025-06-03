#!/usr/bin/env zsh
# =============================================================================
# Modern macOS Setup Script for zsh
# =============================================================================
# This script automates the setup of a new Mac with modern development tools,
# applications, and system preferences. Updated for Apple Silicon compatibility
# and current macOS versions.
#
# Usage: /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/Ciderbytes%20Mac%20Setup.sh)"
# =============================================================================

# =============================================================================
# FULL DISK ACCESS WARNING
# =============================================================================

echo -e "\n⚠️  This script needs Terminal to have Full Disk Access in order to configure Safari and other system preferences."
echo "   1. Go to System Settings > Privacy & Security > Full Disk Access."
echo "   2. Add your Terminal app (or iTerm, etc) to the list."
echo "   3. Restart Terminal after making the change."
echo "   4. Then re-run this script if you just made the change."
echo

# Open the Full Disk Access pane in System Settings (macOS 13+)
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

read "?Press [Enter] to confirm you have granted Full Disk Access and wish to continue..."

# =============================================================================
# INITIAL SETUP AND PERMISSIONS
# =============================================================================

echo "🚀 Starting modern macOS setup process..."
echo "📋 This script will configure your Mac with development tools and preferences"

# Request sudo access upfront to avoid interruptions during installation
echo "🔐 Requesting administrator privileges..."
sudo -v

# Keep sudo alive throughout the script execution
# This background process refreshes sudo every 60 seconds
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# =============================================================================
# CONFIGURATION VARIABLES AND USER PREFERENCES
# =============================================================================

echo -e "\n⚙️  Configuration Setup"
echo "Let's configure some preferences for your setup process"

# Brewfile Configuration
echo -e "\n📦 Brewfile Configuration"
echo "Choose your Brewfile source:"
echo "1. Default hosted Brewfile (from this repository)"
echo "2. Local Brewfile (specify path)"
echo "3. Alternative hosted Brewfile (specify URL)"

read "brewfile_choice?Select option [1/2/3]: "

case $brewfile_choice in
    1)
        BREWFILE_SOURCE="hosted"
        BREWFILE_URL="https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/brewfile"
        BREWFILE_PATH="~/Brewfile"
        echo "✅ Using default hosted Brewfile"
        ;;
    2)
        BREWFILE_SOURCE="local"
        read "local_path?Enter the full path to your local Brewfile: "
        # Expand tilde to home directory if present
        BREWFILE_PATH="${local_path/#\~/$HOME}"
        BREWFILE_URL=""
        
        # Validate file exists
        if [[ ! -f "$BREWFILE_PATH" ]]; then
            echo "❌ File not found: $BREWFILE_PATH"
            echo "Please ensure the file exists and try again"
            exit 1
        fi
        echo "✅ Using local Brewfile: $BREWFILE_PATH"
        ;;
    3)
        BREWFILE_SOURCE="custom_hosted"
        read "custom_url?Enter the URL to your hosted Brewfile: "
        BREWFILE_URL="$custom_url"
        BREWFILE_PATH="~/Brewfile"
        echo "✅ Using custom hosted Brewfile: $BREWFILE_URL"
        ;;
    *)
        echo "❌ Invalid selection. Using default hosted Brewfile"
        BREWFILE_SOURCE="hosted"
        BREWFILE_URL="https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/brewfile"
        BREWFILE_PATH="~/Brewfile"
        ;;
esac

# Additional Configuration Variables
echo -e "\n🔧 Additional Configuration"

# SSH Key Management Preference
echo "SSH Key Management:"
echo "1. Traditional local SSH keys"
echo "2. 1Password SSH key management"
read "ssh_default?Default SSH key management [1/2]: "

# Store configuration summary
echo -e "\n📋 Configuration Summary:"
echo "Brewfile Source: $BREWFILE_SOURCE"
if [[ -n "$BREWFILE_URL" ]]; then
    echo "Brewfile URL: $BREWFILE_URL"
fi
echo "Brewfile Path: $BREWFILE_PATH"
echo "SSH Default: $([[ $ssh_default == "1" ]] && echo "Traditional" || echo "1Password")"

read "?Press [Enter] to continue with setup..."


# =============================================================================
# APP STORE AUTHENTICATION
# =============================================================================

echo -e "\n📱 \033[1;31mIMPORTANT: Please sign into the App Store before proceeding\033[0m"
echo "This is required for installing apps via the Mac App Store CLI (mas)"
open -a /System/Applications/App\ Store.app
read "?Press [Enter] after signing into the App Store..."

# =============================================================================
# ROSETTA 2 INSTALLATION (Apple Silicon Macs)
# =============================================================================

echo -e "\n🔧 Checking Rosetta 2 installation requirements..."

# Parse macOS version to determine if we're on macOS 11+ (Big Sur and later)
# Rosetta 2 is only needed on macOS 11+ running on Apple Silicon
OLDIFS=$IFS
IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"
IFS=$OLDIFS

if [[ ${osvers_major} -ge 11 ]]; then
    echo "✅ Running macOS ${osvers_major}.${osvers_minor}.${osvers_dot_version} - checking processor type..."
    
    # Check if we're running on Intel or Apple Silicon
    processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
    
    if [[ -n "$processor" ]]; then
        echo "💻 Intel processor detected - Rosetta 2 not required"
    else
        echo "🍎 Apple Silicon processor detected - checking Rosetta 2 status..."
        
        # Check if Rosetta 2 is already installed by looking for its LaunchDaemon
        if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
            echo "📦 Installing Rosetta 2 for Intel app compatibility..."
            /usr/sbin/softwareupdate --install-rosetta --agree-to-license
            
            if [[ $? -eq 0 ]]; then
                echo "✅ Rosetta 2 installation completed successfully"
            else
                echo "❌ Rosetta 2 installation failed - some Intel apps may not work"
                exit 1
            fi
        else
            echo "✅ Rosetta 2 is already installed"
        fi
    fi
else
    echo "📱 Running macOS ${osvers_major}.${osvers_minor}.${osvers_dot_version}"
    echo "ℹ️  Rosetta 2 is not required for this macOS version"
fi
# =============================================================================
# SYSTEM SOFTWARE UPDATES (Optional)
# =============================================================================

echo -e "\n🔄 System Software Updates"
read "do_updates?Would you like to check for and install macOS updates and security data? [Y/n] "
do_updates=${do_updates:-Y}

if [[ "$do_updates" =~ ^[Yy]$ ]]; then
    echo -e "\n🔄 Updating system software and security data..."
    echo "This includes macOS updates, security patches, and system data files"
    # Modern softwareupdate command that includes security data updates
    # like MRT (Malware Removal Tool), XProtect, and other security components
    sudo softwareupdate -l --include-config-data # List available updates
    sudo softwareupdate -i -a # Install all available updates
    echo "✅ System software update completed"
else
    echo "⏭️  Skipping system software updates as requested."
fi

# =============================================================================
# ENABLE TOUCH ID FOR SUDO (Sonoma and Later)
# =============================================================================

# Detect macOS version (major version 14 = Sonoma)
macos_version=$(sw_vers -productVersion)
macos_major=$(echo "$macos_version" | cut -d. -f1)

if [[ $macos_major -ge 14 ]]; then
    echo -e "\n🔒 Enabling Touch ID for sudo authentication (macOS Sonoma or later)..."
    # Use sed and tee to uncomment the pam_tid.so line in the template and write it to sudo_local
    if [[ -f /etc/pam.d/sudo_local.template ]]; then
        if sudo sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null; then
            echo "✅ Touch ID for sudo enabled. This will persist through OS updates."
        else
            echo "❌ Failed to enable Touch ID for sudo."
        fi
    else
        echo "❌ /etc/pam.d/sudo_local.template not found. Skipping Touch ID setup."
    fi
else
    echo "ℹ️  Touch ID for sudo is only supported on macOS Sonoma (14.x) and later."
fi


# =============================================================================
# GIT CONFIGURATION
# =============================================================================

echo -e "\n📝 Configuring Git with modern best practices..."

# Download and set up global gitignore for macOS
# This prevents common macOS files (.DS_Store, etc.) from being committed
if [[ ! -f ~/.gitignore ]]; then
    echo "📥 Downloading macOS-specific gitignore file..."
    if curl -fsSL https://raw.githubusercontent.com/github/gitignore/main/Global/macOS.gitignore -o ~/.gitignore; then
        git config --global core.excludesfile ~/.gitignore
        echo "✅ Global gitignore configured"
    else
        echo "❌ Failed to download gitignore file"
    fi
fi


# Configure Git line ending handling for cross-platform compatibility
echo "🔧 Configuring Git line ending handling..."
git config --global core.autocrlf input

# Set default branch name to 'main' (modern standard)
echo "🌿 Setting default Git branch to 'main'..."
git config --global init.defaultBranch main

# Configure pull strategy to avoid merge commits by default
git config --global pull.rebase false

echo "✅ Git configuration completed"

# =============================================================================
# HOMEBREW INSTALLATION AND SETUP
# =============================================================================

echo -e "\n🍺 Setting up Homebrew package manager..."

# Check if Homebrew is already installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    echo "This may take several minutes and will install Xcode Command Line Tools if needed"
    
    # Use the official Homebrew installation script (updated URL with HEAD branch)
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configure Homebrew environment based on processor architecture
    echo "🔧 Configuring Homebrew environment..."
    if [[ $(uname -m) == "arm64" ]]; then
        # Apple Silicon Macs - Homebrew installs to /opt/homebrew
        echo "🍎 Configuring Homebrew for Apple Silicon..."
        eval "$(/opt/homebrew/bin/brew shellenv)"
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        # Intel Macs - Homebrew installs to /usr/local
        echo "💻 Configuring Homebrew for Intel..."
        eval "$(/usr/local/bin/brew shellenv)"
        HOMEBREW_PREFIX="/usr/local"
    fi
    
    # Add Homebrew to shell profile for future sessions
    echo "📝 Adding Homebrew to shell profile..."
    if [[ ! -f ~/.zprofile ]]; then
        touch ~/.zprofile
    fi
    
    if [[ $(uname -m) == "arm64" ]]; then
        if ! grep -q '/opt/homebrew/bin/brew shellenv' ~/.zprofile; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
    else
        if ! grep -q '/usr/local/bin/brew shellenv' ~/.zprofile; then
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        fi
    fi
else
    echo "✅ Homebrew is already installed"
    # Set HOMEBREW_PREFIX for existing installation
    if [[ $(uname -m) == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
fi

# Update Homebrew and upgrade existing packages
echo "🔄 Updating Homebrew and installed packages..."
brew update
brew upgrade

echo "✅ Homebrew setup completed"

# =============================================================================
# MAC APP STORE CLI INSTALLATION
# =============================================================================

echo -e "\n🏪 Installing Mac App Store command line interface..."
echo "MAS allows installing and updating App Store apps from the command line"

brew install mas

echo "✅ MAS (Mac App Store CLI) installed"

# =============================================================================
# XCODE INSTALLATION AND SETUP 
# =============================================================================

echo -e "\n🛠️  Checking Xcode installation..."

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &> /dev/null; then
    echo "📦 Installing Xcode Command Line Tools..."
    echo "This is required for development tools and compiling software"
    xcode-select --install
    
    # Wait for user to complete the installation
    echo "⏳ Please complete the Xcode Command Line Tools installation in the popup window"
    read "?Press [Enter] after the installation completes..."
fi

# Check if full Xcode is installed, install if needed
if ! command -v xcodebuild &> /dev/null; then
    echo "📱 Installing full Xcode from App Store..."
    echo "This is a large download and may take considerable time"
    mas install 497799835  # Xcode App Store ID
    
    echo "✅ Xcode installation completed"
    echo "📋 Accepting Xcode license agreement..."
    sudo xcodebuild -license accept
else
    echo "✅ Xcode is already installed"
fi

# =============================================================================
# CONFIGURATION FILES DOWNLOAD
# =============================================================================

echo -e "\n📥 Downloading configuration files..."

# Download Powerlevel10k configuration for zsh theming
echo "🎨 Downloading Powerlevel10k theme configuration..."
if curl -fsSL --output ~/.p10k.zsh https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.p10k.zsh; then
    echo "✅ Powerlevel10k configuration downloaded"
else
    echo "❌ Failed to download Powerlevel10k configuration"
fi

# Handle Brewfile based on user configuration
echo "📦 Setting up Brewfile..."
case $BREWFILE_SOURCE in
    "hosted"|"custom_hosted")
        echo "📥 Downloading Brewfile from: $BREWFILE_URL"
        # Expand tilde in path for curl command
        EXPANDED_BREWFILE_PATH="${BREWFILE_PATH/#\~/$HOME}"
        
        if curl -fsSL --output "$EXPANDED_BREWFILE_PATH" "$BREWFILE_URL"; then
            echo "✅ Brewfile downloaded successfully"
        else
            echo "❌ Failed to download Brewfile from $BREWFILE_URL"
            exit 1
        fi
        ;;
    "local")
        echo "📂 Using local Brewfile: $BREWFILE_PATH"
        # Copy local file to standard location if it's not already there
        if [[ "$BREWFILE_PATH" != "$HOME/Brewfile" ]]; then
            echo "📋 Copying local Brewfile to ~/Brewfile for processing..."
            cp "$BREWFILE_PATH" "$HOME/Brewfile"  # Use $HOME instead of ~
            BREWFILE_PATH="$HOME/Brewfile"
        fi
        echo "✅ Local Brewfile ready"
        ;;
esac

# =============================================================================
# BREWFILE REVIEW AND EDITING
# =============================================================================

echo -e "\n📝 Brewfile Review"
echo "Your Brewfile is ready for installation"

# Expand the path for editor access
EXPANDED_BREWFILE_PATH="${BREWFILE_PATH/#\~/$HOME}"

# Prompt user to review/edit Brewfile before installation
read "edit_brewfile?Would you like to review/edit the Brewfile before installation? [y/N] "
if [[ "$edit_brewfile" =~ ^[Yy]$ ]]; then
    # Determine which editor to use
    if [[ -n "$EDITOR" ]]; then
        editor="$EDITOR"
        echo "📝 Opening Brewfile in $editor (from \$EDITOR)..."
    elif command -v code &> /dev/null; then
        editor="code"
        echo "📝 Opening Brewfile in Visual Studio Code..."
    elif command -v nano &> /dev/null; then
        editor="nano"
        echo "📝 Opening Brewfile in nano..."
    else
        editor="vi"
        echo "📝 Opening Brewfile in vi (fallback editor)..."
    fi
    
    # Open the Brewfile in the chosen editor
    $editor "$EXPANDED_BREWFILE_PATH"
    
    echo "✅ Brewfile editing session completed"
    
    # Give user a moment to see what happened
    read "?Press [Enter] to continue with installation..."
else
    echo "⏭️  Proceeding with installation using current Brewfile"
fi

# =============================================================================
# APPLICATION INSTALLATION VIA HOMEBREW
# =============================================================================

echo -e "\n📦 Installing applications and tools from Brewfile..."
echo "This will install development tools, applications, and utilities"
echo "Using Brewfile: $BREWFILE_PATH"

# Expand tilde in path for brew bundle command
EXPANDED_BREWFILE_PATH="${BREWFILE_PATH/#\~/$HOME}"

# Check what packages are missing from the Brewfile
echo "🔍 Checking Brewfile dependencies..."
if brew bundle check --file="$EXPANDED_BREWFILE_PATH"; then
    echo "✅ All Brewfile dependencies are already satisfied"
else
    echo "📋 The following packages need to be installed:"
    brew bundle check --file="$EXPANDED_BREWFILE_PATH" 2>&1 | grep "is not installed" || true
    
    echo -e "\n⏳ Starting installation process..."
    echo "Installation may take 15-30 minutes depending on your internet connection"
    
    brew bundle install -v --file="$EXPANDED_BREWFILE_PATH"
    echo "✅ Application installation from Brewfile completed"
fi
# =============================================================================
# SSH KEY GENERATION AND CONFIGURATION
# =============================================================================

echo -e "\n🔑 SSH Key Setup"
echo "Using your configured SSH key management preference..."

# Use the configured default from earlier
ssh_choice="$ssh_default"

case $ssh_choice in
    1)
        echo -e "\n🔐 Setting up traditional SSH keys..."
        read "emailaddress?Enter your email address for the SSH key: "
        
        # Generate ed25519 SSH key locally
        echo "🔑 Generating ed25519 SSH key pair..."
        ssh-keygen -t ed25519 -C "$emailaddress"
        
        # Start SSH agent and configure keychain
        echo "🚀 Starting SSH agent..."
        eval "$(ssh-agent -s)"
        
        # Create SSH config directory and file if they don't exist
        echo "📝 Configuring SSH client settings..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        
        if [[ ! -f ~/.ssh/config ]]; then
            touch ~/.ssh/config
            chmod 600 ~/.ssh/config
        fi
        
        # Add SSH configuration for automatic key loading and keychain integration
        if ! grep -q "Host \*" ~/.ssh/config; then
            echo "🔧 Adding SSH configuration for keychain integration..."
            cat >> ~/.ssh/config << 'EOF'
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        fi
        
        # Add the key to SSH agent with keychain integration
        echo "🔐 Adding SSH key to agent and keychain..."
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
        
        # Copy public key to clipboard
        pbcopy < ~/.ssh/id_ed25519.pub
        echo -e "\n📋 SSH public key copied to clipboard"
        ;;
        
    2)
        echo -e "\n🔐 Using 1Password SSH key management..."
        echo "Assuming SSH keys are already saved in your 1Password vault"
        
        # Configure SSH client to use 1Password SSH Agent
        echo "🔧 Configuring SSH client for 1Password SSH Agent..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        
        if [[ ! -f ~/.ssh/config ]]; then
            touch ~/.ssh/config
            chmod 600 ~/.ssh/config
        fi
        
        # Add 1Password SSH Agent configuration if not already present
        if ! grep -q "IdentityAgent" ~/.ssh/config; then
            cat >> ~/.ssh/config << 'EOF'

# 1Password SSH Agent
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        fi
        
        echo "✅ SSH client configured for 1Password SSH Agent"
        echo "📋 Your SSH keys are managed in 1Password vault"
        echo "💡 Use 1Password browser extension to add public keys to GitHub"
        ;;
        
    *)
        echo "❌ Invalid selection. Skipping SSH key setup."
        ;;
esac

# Open GitHub SSH settings for both options
if [[ $ssh_choice == "1" || $ssh_choice == "2" ]]; then
    echo -e "\n🌐 Opening GitHub SSH settings..."
    echo -e "\033[1;34mAdd your SSH key at: https://github.com/settings/ssh\033[0m"
    open "https://github.com/settings/ssh"
    
    if [[ $ssh_choice == "1" ]]; then
        echo -e "\033[1;31m📎 SSH key copied to clipboard - paste it into GitHub\033[0m"
    else
        echo -e "\033[1;31m🔑 Use 1Password browser extension to fill your public key\033[0m"
    fi
    
    read "?Press [Enter] after adding the SSH key to GitHub..."
fi


# =============================================================================
# OH MY ZSH INSTALLATION AND CONFIGURATION
# =============================================================================

echo -e "\n🐚 Setting up Oh My Zsh and shell configuration..."

# Backup existing .zshrc if it exists
if [[ -f ~/.zshrc ]]; then
    backup_name="$HOME/.zshrc.bak.$(date +%Y%m%d_%H%M%S)"
    echo "💾 Backing up existing .zshrc to $backup_name"
    mv ~/.zshrc "$backup_name"
fi

# Install Oh My Zsh if not already installed
if [[ ! -d ~/.oh-my-zsh ]]; then
    echo "📦 Installing Oh My Zsh framework..."
    echo "Oh My Zsh provides a framework for managing zsh configuration and plugins"
    
    # RUNZSH=no prevents automatic shell switching during installation
    RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "✅ Oh My Zsh installed"
else
    echo "✅ Oh My Zsh is already installed"
fi

# Download and install custom .zshrc configuration
echo "📝 Installing custom .zshrc configuration..."
curl -fsSL https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master/.zshrc > ~/.zshrc

# =============================================================================
# ZSH PLUGINS INSTALLATION
# =============================================================================

echo -e "\n🔌 Installing Zsh plugins for enhanced functionality..."

# Set custom plugins directory
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# Install zsh-autosuggestions - suggests commands as you type based on history
echo "💡 Installing zsh-autosuggestions..."
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    echo "✅ zsh-autosuggestions installed"
else 
    echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting - highlights commands as you type
echo "🎨 Installing zsh-syntax-highlighting..."
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    echo "✅ zsh-syntax-highlighting installed"
else 
    echo "✅ zsh-syntax-highlighting already installed"
fi

# Install z - jump around directories based on frequency and recency
echo "📁 Installing z (directory jumping tool)..."
if [[ ! -d "$ZSH_CUSTOM/plugins/z" ]]; then
    git clone https://github.com/rupa/z.git "$ZSH_CUSTOM/plugins/z"
    echo "✅ z installed"
else 
    echo "✅ z already installed"
fi

# Install zsh-nvm - manages Node Version Manager installation and configuration
echo "📦 Installing zsh-nvm (Node Version Manager)..."
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-nvm" ]]; then
    git clone https://github.com/lukechilds/zsh-nvm "$ZSH_CUSTOM/plugins/zsh-nvm"
    echo "✅ zsh-nvm installed"
    echo "💡 This plugin will automatically install and manage NVM for you"
else 
    echo "✅ zsh-nvm already installed"
fi


# Update all custom plugins to latest versions
echo "🔄 Updating all custom plugins..."
for plugin in "$ZSH_CUSTOM"/plugins/*/; do
    if [[ -d "$plugin/.git" ]]; then
        plugin_name=$(basename "$plugin")
        echo "🔄 Updating $plugin_name..."
        git -C "$plugin" pull
    fi
done

# Fix Homebrew permissions for zsh completion
echo "🔧 Fixing Homebrew permissions for shell completion..."
chmod -R go-w "$HOMEBREW_PREFIX/share" 2>/dev/null || true

echo "✅ Zsh plugins installation completed"

# =============================================================================
# MACKUP BACKUP RESTORATION (Deprecated - will be removed in future versions)
# =============================================================================

echo -e "\n💾 Mackup Configuration Restore"

# Check macOS version - Mackup is not supported on Sonoma (14.0) and later
macos_version=$(sw_vers -productVersion)
macos_major=$(echo "$macos_version" | cut -d. -f1)

if [[ $macos_major -ge 14 ]]; then
    echo -e "\n⚠️  \033[1;33mSkipping Mackup restore - not supported on macOS $macos_version (Sonoma and later)\033[0m"
else
    echo "Mackup can restore your application settings and preferences from iCloud"
    echo "✅ macOS $macos_version detected - Mackup is supported"

    read "doit?Restore application settings from Mackup? [y/N] "
    case $doit in  
        y|Y) 
            echo -e "\n☁️  \033[1;31mPlease ensure Mackup folder is downloaded from iCloud before proceeding\033[0m"
            echo "Opening iCloud Drive folder..."
            open ~/Library/Mobile\ Documents/com~apple~CloudDocs/
            read "?Press [Enter] after confirming Mackup folder is available locally..."
            
            # Check if Mackup configuration exists and create symlink
            mackup_config="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Mackup/.mackup.cfg"
            if [[ -f "$mackup_config" ]]; then
                echo "🔗 Linking Mackup configuration..."
                ln -sf "$mackup_config" ~/.mackup.cfg
                
                echo "📦 Restoring application settings with Mackup..."
                mackup restore
                echo "✅ Mackup restore completed"
            else
                echo "❌ Mackup configuration file not found at expected location"
                echo "Expected: $mackup_config"
            fi
            ;;
        *) 
            echo "⏭️  Skipping Mackup restore"
            ;;
    esac
fi


# =============================================================================
# GIT USER CONFIGURATION
# =============================================================================

echo -e "\n👤 Git User Configuration"
echo "Setting up your Git identity for commits and repositories"

# Get current global git user.name and user.email, if set
current_git_name=$(git config --global user.name)
current_git_email=$(git config --global user.email)

# Prompt for user.name
if [[ -n "$current_git_name" ]]; then
    echo "Current Git user.name: $current_git_name"
    read "update_name?Would you like to update your Git user.name? [y/N] "
    if [[ "$update_name" =~ ^[Yy]$ ]]; then
        read "githubuser?Enter your new Git user.name: "
    else
        githubuser="$current_git_name"
    fi
else
    read "githubuser?Enter your Git user.name: "
fi

# Prompt for user.email
if [[ -n "$current_git_email" ]]; then
    echo "Current Git user.email: $current_git_email"
    read "update_email?Would you like to update your Git user.email? [y/N] "
    if [[ "$update_email" =~ ^[Yy]$ ]]; then
        read "githubuseremail?Enter your new Git user.email: "
    else
        githubuseremail="$current_git_email"
    fi
else
    read "githubuseremail?Enter your Git user.email: "
fi

# Configure Git user information globally
echo "📝 Configuring Git user information..."
git config --global user.name "$githubuser"
git config --global user.email "$githubuseremail"

# Set up credential helper for macOS keychain integration
git config --global credential.helper osxkeychain

# Set Visual Studio Code as the default Git editor
git config --global core.editor "code --wait"

echo "✅ Git user configuration completed"

# =============================================================================
# MACOS SYSTEM PREFERENCES CONFIGURATION
# =============================================================================

echo -e "\n⚙️  Configuring macOS system preferences for development..."
echo "Applying developer-friendly system settings and preferences"

# FINDER PREFERENCES
echo "📁 Configuring Finder preferences..."

# Enable text selection in Quick Look previews
defaults write com.apple.finder QLEnableTextSelection -bool true

# Set Finder to use column view by default (better for development)
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Set new Finder windows to open in home directory
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME"

# Disable file extension change warnings (useful for development)
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# DOCK PREFERENCES
echo "🚢 Configuring Dock preferences..."

# Enable Dock auto-hide for more screen space
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay for instant appearance
defaults write com.apple.dock autohide-delay -float 0

# Speed up auto-hide animation
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Position Dock on the left side for more vertical space
defaults write com.apple.dock orientation -string "left"

# SCREENSHOT PREFERENCES
echo "📸 Configuring screenshot preferences..."

# Create Screenshots folder on Desktop
mkdir -p ~/Desktop/Screenshots

# Set screenshot save location to Screenshots folder
defaults write com.apple.screencapture location ~/Desktop/Screenshots

# Set screenshot format to PNG (better quality than JPEG)
defaults write com.apple.screencapture type -string "png"

# SAFARI DEVELOPER PREFERENCES
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

# CHROME PREFERENCES
echo "🌐 Configuring Chrome preferences..."

# Disable annoying backswipe navigation in Chrome
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

# =============================================================================
# ADDITIONAL MACOS SYSTEM PREFERENCES CONFIGURATION (Disabled by default)
# =============================================================================

# echo -e "\n⚙️  Configuring additional macOS system preferences..."

# # SECURITY AND GATEKEEPER SETTINGS
# echo "🔒 Configuring security preferences..."

# # Disable macOS Gatekeeper (allows installation of apps from anywhere)
# # WARNING: This reduces security by allowing unsigned applications
# echo "⚠️  Disabling macOS Gatekeeper (allows apps from anywhere)..."
# sudo spctl --master-disable
# sudo defaults write /var/db/SystemPolicy-prefs.plist enabled -string no
# defaults write com.apple.LaunchServices LSQuarantine -bool false

# # DOCUMENT SAVING PREFERENCES
# echo "💾 Configuring document saving preferences..."

# # Save to disk (local) by default instead of iCloud
# # This prevents the iCloud save dialog from appearing by default
# defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# # TEXT INPUT AND AUTOCORRECTION SETTINGS
# echo "⌨️  Configuring text input preferences..."

# # Disable smart quotes (prevents curly quotes in code/terminal)
# # Smart quotes can cause issues when copying code snippets
# defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# # Disable smart dashes (prevents em-dashes and en-dashes)
# # Smart dashes can interfere with command-line usage and code
# defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# # FINDER FILE EXTENSION SETTINGS
# echo "📁 Configuring Finder file extension display..."

# # Show all filename extensions in Finder by default
# # This is important for developers to see file types clearly
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# echo "✅ Additional system preferences configured"


# =============================================================================
# VISUAL STUDIO CODE PATH CONFIGURATION
# =============================================================================

echo -e "\n💻 Configuring Visual Studio Code..."

# Add VS Code 'code' command to PATH if not already present
if ! grep -q "Visual Studio Code" ~/.zshrc; then
    echo "🔧 Adding Visual Studio Code to PATH..."
    cat >> ~/.zshrc << 'EOF'

# Add Visual Studio Code (code) command to PATH
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
EOF
    echo "✅ VS Code command line tool configured"
fi

# =============================================================================
# SYSTEM RESTART AND CLEANUP
# =============================================================================

echo -e "\n🧹 Performing cleanup and applying changes..."

# Restart affected system applications to apply preference changes
echo "🔄 Restarting system applications..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# Clean up Homebrew cache and check system health
echo "🧹 Cleaning up Homebrew..."
brew cleanup

echo "🏥 Running Homebrew doctor to check system health..."
brew doctor

# =============================================================================
# COMPLETION MESSAGE AND NEXT STEPS
# =============================================================================

echo -e "\n🎉 \033[1;32m═══════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;32m✅ macOS setup completed successfully!\033[0m"
echo -e "\033[1;32m═══════════════════════════════════════════════════════\033[0m"

echo -e "\n📋 \033[1;33mRecommended next steps:\033[0m"
echo -e "\033[1;36m1.\033[0m 🔄 Restart your computer to ensure all changes take effect"
echo -e "\033[1;36m2.\033[0m 🐚 Open a new terminal and run: \033[1;31momz update\033[0m"
echo -e "\033[1;36m3.\033[0m 🎨 Configure iTerm2 font to 'MesloLGS NF' for proper theme display"
echo -e "\033[1;36m4.\033[0m 💻 Set VS Code terminal font to 'MesloLGS NF' in settings"
echo -e "\033[1;36m5.\033[0m ⚡ Run \033[1;31mp10k configure\033[0m to customize your terminal theme"

echo -e "\n🛠️  \033[1;33mInstalled tools and their usage:\033[0m"
echo -e "\033[1;36m•\033[0m 🍺 \033[1;32mbrew\033[0m - Package manager for macOS"
echo -e "\033[1;36m•\033[0m 🏪 \033[1;32mmas\033[0m - Mac App Store command line interface"
echo -e "\033[1;36m•\033[0m 🔑 \033[1;32mssh\033[0m - Secure shell with ed25519 key configured"
echo -e "\033[1;36m•\033[0m 📝 \033[1;32mgit\033[0m - Version control with modern configuration"
echo -e "\033[1;36m•\033[0m 🐚 \033[1;32mzsh\033[0m - Enhanced shell with Oh My Zsh framework"

echo -e "\n🎯 \033[1;33mYour development environment is now ready!\033[0m"

# Start a new zsh session to load all configurations
echo -e "\n🚀 Starting new shell session with updated configuration..."
exec zsh
