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

# Base Paths
REPO_BASE_TARGET=${SETUP_BASE_TARGET:-"https://raw.githubusercontent.com/CiderBytes/Brewmaster-Kit/master"}
REPO_P10K_TARGET=${SETUP_P10K_TARGET:-"$REPO_BASE_TARGET/recipes/shell/.p10k.zsh"}
GITIGNORE_TARGET=${SETUP_GITIGNORE_TARGET:-"https://raw.githubusercontent.com/github/gitignore/main/Global/macOS.gitignore"}

# =============================================================================
# BREWFILE RECIPES
# =============================================================================
CORE_BREW_TARGET=${SETUP_CORE_BREW:-"$REPO_BASE_TARGET/recipes/brew/core_brewfile.txt"}
CATALOG_TARGET=${SETUP_CATALOG_TARGET:-"$REPO_BASE_TARGET/recipes/brew/catalog_brewfile.txt"}
DEFAULT_MANIFEST_TARGET=${SETUP_MANIFEST_TARGET:-"$REPO_BASE_TARGET/recipes/brew/manifest.txt"}

RECIPE_1_NAME=${SETUP_RECIPE_1_NAME:-"Software Developer"}
RECIPE_1_TARGET=${SETUP_RECIPE_1_TARGET:-"$REPO_BASE_TARGET/recipes/brew/dev_brewfile.txt"}

RECIPE_2_NAME=${SETUP_RECIPE_2_NAME:-"WordPress Developer"}
RECIPE_2_TARGET=${SETUP_RECIPE_2_TARGET:-"$REPO_BASE_TARGET/recipes/brew/wp_brewfile.txt"}

RECIPE_3_NAME=${SETUP_RECIPE_3_NAME:-"Content Creator"}
RECIPE_3_TARGET=${SETUP_RECIPE_3_TARGET:-"$REPO_BASE_TARGET/recipes/brew/content_brewfile.txt"}

RECIPE_4_NAME=${SETUP_RECIPE_4_NAME:-"Data Scientist"}
RECIPE_4_TARGET=${SETUP_RECIPE_4_TARGET:-"$REPO_BASE_TARGET/recipes/brew/data_brewfile.txt"}

# =============================================================================
# MACOS PREFERENCE RECIPES
# =============================================================================
PREFS_CORE_TARGET=${SETUP_PREFS_CORE:-"$REPO_BASE_TARGET/recipes/prefs/core_prefs.txt"}
PREFS_CATALOG_TARGET=${SETUP_PREFS_CATALOG:-"$REPO_BASE_TARGET/recipes/prefs/catalog_prefs.txt"}
PREFS_MANIFEST_TARGET=${SETUP_PREFS_MANIFEST:-"$REPO_BASE_TARGET/recipes/prefs/manifest.txt"}

PREFS_1_NAME=${SETUP_PREFS_1_NAME:-"Software Developer Prefs"}
PREFS_1_TARGET=${SETUP_PREFS_1_TARGET:-"$REPO_BASE_TARGET/recipes/prefs/dev_prefs.txt"}

PREFS_2_NAME=${SETUP_PREFS_2_NAME:-"WordPress Developer Prefs"}
PREFS_2_TARGET=${SETUP_PREFS_2_TARGET:-"$REPO_BASE_TARGET/recipes/prefs/wp_prefs.txt"}

PREFS_3_NAME=${SETUP_PREFS_3_NAME:-"Content Creator Prefs"}
PREFS_3_TARGET=${SETUP_PREFS_3_TARGET:-"$REPO_BASE_TARGET/recipes/prefs/content_prefs.txt"}

PREFS_4_NAME=${SETUP_PREFS_4_NAME:-"Data Scientist Prefs"}
PREFS_4_TARGET=${SETUP_PREFS_4_TARGET:-"$REPO_BASE_TARGET/recipes/prefs/data_prefs.txt"}

# =============================================================================
# SHELL PROFILE RECIPES
# =============================================================================
SHELL_CORE_TARGET=${SETUP_SHELL_CORE:-"$REPO_BASE_TARGET/recipes/shell/core_zshrc.txt"}
SHELL_MANIFEST_TARGET=${SETUP_SHELL_MANIFEST:-"$REPO_BASE_TARGET/recipes/shell/manifest.txt"}

SHELL_1_NAME=${SETUP_SHELL_1_NAME:-"Software Developer Shell"}
SHELL_1_TARGET=${SETUP_SHELL_1_TARGET:-"$REPO_BASE_TARGET/recipes/shell/dev_zshrc.txt"}

SHELL_2_NAME=${SETUP_SHELL_2_NAME:-"WordPress Developer Shell"}
SHELL_2_TARGET=${SETUP_SHELL_2_TARGET:-"$REPO_BASE_TARGET/recipes/shell/wp_zshrc.txt"}

SHELL_3_NAME=${SETUP_SHELL_3_NAME:-"Content Creator Shell"}
SHELL_3_TARGET=${SETUP_SHELL_3_TARGET:-"$REPO_BASE_TARGET/recipes/shell/content_zshrc.txt"}

SHELL_4_NAME=${SETUP_SHELL_4_NAME:-"Data Scientist Shell"}
SHELL_4_TARGET=${SETUP_SHELL_4_TARGET:-"$REPO_BASE_TARGET/recipes/shell/data_zshrc.txt"}


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

# Global Helper: Determine best available text editor
get_editor() {
    if [[ -n "$EDITOR" ]]; then
        echo "$EDITOR"
    elif command -v code &> /dev/null; then
        echo "code" # <--- Removed --wait so the terminal doesn't freeze
    elif command -v nano &> /dev/null; then
        echo "nano"
    else
        echo "vi"
    fi
}

# Global Helper: Fetch URL or Local Path safely (Overwrites destination)
fetch_target() {
    local target="$1"
    local dest="$2"
    
    if [[ "$target" == http* ]]; then
        if ! curl -fsSL --output "$dest" "$target"; then
            echo "❌ Error: Could not download $target."
            return 1
        fi
    else
        local local_file="${target/#\~/$HOME}"
        if [[ -f "$local_file" ]]; then
            cp "$local_file" "$dest"
        else
            echo "❌ Error: File not found at $local_file."
            return 1
        fi
    fi
}

# Global Helper: Fetch file with auto-extension swap and interactive fallback
fetch_core_with_fallback() {
    local original_target="$1"
    local dest="$2"
    local core_name="$3"
    local current_target="$original_target"
    
    while true; do
        # Attempt 1: Try the exact target provided
        if fetch_target "$current_target" "$dest"; then
            echo "✅ $core_name loaded."
            return 0
        fi
        
        # Attempt 2: Auto-swap .txt and .toml
        local alt_target=""
        if [[ "$current_target" == *.txt ]]; then
            alt_target="${current_target%.txt}.toml"
        elif [[ "$current_target" == *.toml ]]; then
            alt_target="${current_target%.toml}.txt"
        fi
        
        if [[ -n "$alt_target" ]]; then
            log_verbose "Original target failed. Trying alternative extension: $alt_target"
            if fetch_target "$alt_target" "$dest"; then
                echo "✅ $core_name loaded (using alternative extension)."
                return 0
            fi
        fi
        
        # Both failed. Trigger the interactive fallback menu.
        echo -e "\n⚠️ \033[1;33m$core_name could not be found (.txt or .toml).\033[0m"
        echo "1. Enter a custom URL or local path"
        echo "2. Continue without $core_name"
        echo "3. Abort this phase"
        
        local fallback_choice
        read "fallback_choice?Select option [1-3]: "
        
        if [[ "$fallback_choice" == "1" ]]; then
            read "current_target?Enter custom path or URL: "
            # Loop restarts with the new target
        elif [[ "$fallback_choice" == "2" ]]; then
            echo "⏭️ Proceeding without $core_name."
            touch "$dest" # Ensures the file exists so downstream logic doesn't crash
            return 0
        else
            echo "❌ Halting phase."
            return 1
        fi
    done
}

# Global Helper: Append URL or Local Path safely (Does not overwrite)
append_target() {
    local target="$1"
    local dest="$2"
    
    if [[ "$target" == http* ]]; then
        if ! curl -fsSL "$target" >> "$dest"; then
            echo "❌ Error: Could not download $target."
            return 1
        fi
    else
        local local_file="${target/#\~/$HOME}"
        if [[ -f "$local_file" ]]; then
            cat "$local_file" >> "$dest"
        else
            echo "❌ Error: File not found at $local_file."
            return 1
        fi
    fi
}

# Global Helper: Fetch Catalog with auto-extension swap and interactive fallback
append_catalog_with_fallback() {
    local original_target="$1"
    local dest="$2"
    local catalog_name="$3"
    local current_target="$original_target"
    
    while true; do
        # Attempt 1: Try the exact target provided
        if append_target "$current_target" "$dest"; then
            echo "✅ $catalog_name appended."
            return 0
        fi
        
        # Attempt 2: Auto-swap .txt and .toml
        local alt_target=""
        if [[ "$current_target" == *.txt ]]; then
            alt_target="${current_target%.txt}.toml"
        elif [[ "$current_target" == *.toml ]]; then
            alt_target="${current_target%.toml}.txt"
        fi
        
        if [[ -n "$alt_target" ]]; then
            log_verbose "Original target failed. Trying alternative extension: $alt_target"
            if append_target "$alt_target" "$dest"; then
                echo "✅ $catalog_name appended (using alternative extension)."
                return 0
            fi
        fi
        
        # Both failed. Trigger the interactive fallback menu.
        # Notice we only offer 2 options here, because Catalogs are optional (no need to abort phase).
        echo -e "\n⚠️ \033[1;33m$catalog_name could not be found (.txt or .toml).\033[0m"
        echo "1. Enter a custom URL or local path"
        echo "2. Continue without $catalog_name"
        
        local fallback_choice
        read "fallback_choice?Select option [1-2]: "
        
        if [[ "$fallback_choice" == "1" ]]; then
            read "current_target?Enter custom path or URL: "
            # Loop restarts with the new target
        else
            echo "⏭️ Proceeding without $catalog_name."
            echo "# Catalog unavailable/skipped." >> "$dest"
            return 0
        fi
    done
}

# Global Helper: Omni-Selector Menu Engine
run_omni_selector() {
    local mode="$1"
    local target_file="$2"
    
    # Map variables dynamically based on the mode requested
    local name_1 target_1 name_2 target_2 name_3 target_3 name_4 target_4
    local manifest_target suffix core_file catalog_file
    
    if [[ "$mode" == "brew" ]]; then
        name_1="$RECIPE_1_NAME"; target_1="$RECIPE_1_TARGET"
        name_2="$RECIPE_2_NAME"; target_2="$RECIPE_2_TARGET"
        name_3="$RECIPE_3_NAME"; target_3="$RECIPE_3_TARGET"
        name_4="$RECIPE_4_NAME"; target_4="$RECIPE_4_TARGET"
        manifest_target="$DEFAULT_MANIFEST_TARGET"
        glob_pattern="*_brewfile.(txt|toml)"
        core_file="core_brewfile"
        catalog_file="catalog_brewfile"
    elif [[ "$mode" == "prefs" ]]; then
        name_1="$PREFS_1_NAME"; target_1="$PREFS_1_TARGET"
        name_2="$PREFS_2_NAME"; target_2="$PREFS_2_TARGET"
        name_3="$PREFS_3_NAME"; target_3="$PREFS_3_TARGET"
        name_4="$PREFS_4_NAME"; target_4="$PREFS_4_TARGET"
        manifest_target="$PREFS_MANIFEST_TARGET"
        glob_pattern="*_prefs.(txt|toml)"
        core_file="core_prefs"
        catalog_file="catalog_prefs"
    elif [[ "$mode" == "shell" ]]; then
        name_1="$SHELL_1_NAME"; target_1="$SHELL_1_TARGET"
        name_2="$SHELL_2_NAME"; target_2="$SHELL_2_TARGET"
        name_3="$SHELL_3_NAME"; target_3="$SHELL_3_TARGET"
        name_4="$SHELL_4_NAME"; target_4="$SHELL_4_TARGET"
        manifest_target="$SHELL_MANIFEST_TARGET"
        glob_pattern="*_zshrc.(txt|toml)"
        core_file="core_zshrc"
        catalog_file="catalog_zshrc"
    fi

    # Dynamic Menu Wording
    if [[ "$mode" == "shell" ]]; then
        echo -e "\n📦 Select a Base Shell Profile:"
        echo "1. Default Core Base ($core_file)"
    else
        echo -e "\n📦 Select an optional overlay to add to the Core Base:"
        echo "1. None (Core Base Only)"
    fi
    echo "2. $name_1"
    echo "3. $name_2"
    echo "4. $name_3"
    echo "5. $name_4"
    echo "6. Custom Recipe (Enter a direct URL or local path)"
    echo "7. Scan Local Directory for Recipes"
    echo "8. Select from a Manifest (URL or Local)"
    
    local choice
    read "choice?Select option [1-8]: "
    
    # Internal function to process the file safely
    apply_recipe() {
        local dl_target="$1"
        local dl_name="$2"
        
        # GitHub URL Auto-Correction for direct browser links
        if [[ "$dl_target" == *"github.com"* && "$dl_target" == *"/blob/"* ]]; then
            dl_target="${dl_target/github.com/raw.githubusercontent.com}"
            dl_target="${dl_target/\/blob\//\/}"
        fi
        
        # Helper to execute fetch (overwrite) or append based on mode
        execute_transfer() {
            local t="$1"
            if [[ "$mode" == "shell" ]]; then
                fetch_target "$t" "$target_file"
            else
                append_target "$t" "$target_file"
            fi
        }

        if [[ "$mode" != "shell" ]]; then
            echo -e "\n\n# --- OVERLAY: $dl_name ---" >> "$target_file"
        fi
        
        # Attempt 1: Try the exact target provided
        if execute_transfer "$dl_target"; then
            echo "✅ $dl_name applied."
            return 0
        fi
        
        # Attempt 2: Auto-swap .txt and .toml
        local alt_target=""
        if [[ "$dl_target" == *.txt ]]; then
            alt_target="${dl_target%.txt}.toml"
        elif [[ "$dl_target" == *.toml ]]; then
            alt_target="${dl_target%.toml}.txt"
        fi
        
        if [[ -n "$alt_target" ]]; then
            log_verbose "Original target failed. Trying alternative extension: $alt_target"
            if execute_transfer "$alt_target"; then
                echo "✅ $dl_name applied (using alternative extension)."
                return 0
            fi
        fi
        
        echo "❌ Error: Could not reach $dl_target or its alternative. Skipping."
    }

    case $choice in
        1) 
            if [[ "$mode" == "shell" ]]; then
                fetch_core_with_fallback "$SHELL_CORE_TARGET" "$target_file" "Core Shell Profile"
            else
                echo "✅ Proceeding with Core Base only."
            fi
            ;;
        2) apply_recipe "$target_1" "$name_1" ;;
        3) apply_recipe "$target_2" "$name_2" ;;
        4) apply_recipe "$target_3" "$name_3" ;;
        5) apply_recipe "$target_4" "$name_4" ;;
        6)
            read "custom_target?Enter the full path or URL to your custom file: "
            apply_recipe "$custom_target" "CUSTOM"
            ;;
        7)
            read "scan_dir?Enter local directory to scan (~/ is accepted): "
            scan_dir="${scan_dir/#\~/$HOME}"
            if [[ -d "$scan_dir" ]]; then
                # Evaluates our dual-extension glob pattern
                local files=($~scan_dir/$~glob_pattern(N))
                
                if [[ ${#files[@]} -gt 0 ]]; then
                    echo -e "\n📂 Found the following recipes in $scan_dir:"
                    local i=1
                    local friendly_names=()
                    local filtered_files=() 
                    
                    for f in "${files[@]}"; do
                        local raw_name=$(basename "$f")
                        
                        # Skip core and catalog variants regardless of extension
                        [[ "$raw_name" == "${core_file}.txt" || "$raw_name" == "${core_file}.toml" ]] && continue
                        [[ "$raw_name" == "${catalog_file}.txt" || "$raw_name" == "${catalog_file}.toml" ]] && continue
                        
                        # Strip either .txt or .toml from the end, then strip the base suffix
                        local base_name="${raw_name%.*}"
                        local friendly_name=""
                        if [[ "$mode" == "brew" ]]; then
                            friendly_name="${base_name%_brewfile}"
                        elif [[ "$mode" == "prefs" ]]; then
                            friendly_name="${base_name%_prefs}"
                        else
                            friendly_name="${base_name%_zshrc}"
                        fi
                        
                        friendly_names[$i]="$friendly_name"
                        filtered_files[$i]="$f"
                        echo "$i. ${(C)friendly_name}"
                        ((i++))
                    done
                    
                    read "file_choice?Select a recipe [1-$((${#friendly_names[@]}))]: "
                    if [[ -n "${friendly_names[$file_choice]}" ]]; then
                        apply_recipe "${filtered_files[$file_choice]}" "${(C)friendly_names[$file_choice]}" 
                    else
                        echo "❌ Invalid selection. Proceeding with Defaults."
                    fi
                else
                    echo "❌ No matching recipe files found in $scan_dir. Proceeding with Defaults."
                fi
            else
                echo "❌ Directory not found. Proceeding with Defaults."
            fi
            ;;
        8)
            read "manifest_loc?Enter manifest URL or local path [Default: $manifest_target]: "
            manifest_loc=${manifest_loc:-$manifest_target}
            
            log_verbose "Reading manifest from $manifest_loc..."
            if [[ "$manifest_loc" == http* ]]; then
                manifest_content=$(curl -fsSL "$manifest_loc" 2>/dev/null)
            else
                manifest_content=$(cat "${manifest_loc/#\~/$HOME}" 2>/dev/null)
            fi
            
            if [[ -n "$manifest_content" ]]; then
                echo -e "\n📜 Recipes available in manifest:"
                local i=1
                local man_urls=()
                local man_names=()
                
                while IFS='|' read -r man_url man_name; do
                    [[ -z "$man_url" || "$man_url" == \#* ]] && continue
                    man_name=${man_name:-"Unnamed Recipe"}
                    echo "$i. $man_name"
                    man_urls[$i]="$man_url"
                    man_names[$i]="$man_name"
                    ((i++))
                done <<< "$manifest_content"
                
                read "man_choice?Select a recipe [1-$((${#man_urls[@]}))]: "
                if [[ -n "${man_urls[$man_choice]}" ]]; then
                    apply_recipe "${man_urls[$man_choice]}" "${man_names[$man_choice]}"
                else
                    echo "❌ Invalid selection. Proceeding with Defaults."
                fi
            else
                echo "❌ Could not load manifest. Proceeding with Defaults."
            fi
            ;;
        *)
            if [[ "$mode" == "shell" ]]; then
                fetch_core_with_fallback "$SHELL_CORE_TARGET" "$target_file" "Core Shell Profile"
            else
                echo "✅ Proceeding with Core Base only."
            fi
            ;;
    esac
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
        log_verbose "Apple Silicon detected. Executing Rosetta 2 functional test..."
        
        # Functional test: Attempt to run a microscopic command under Intel architecture
        if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
            echo -e "\n📦 Installing Rosetta 2 for Intel app compatibility..."
            sudo softwareupdate --install-rosetta --agree-to-license 2>&1 | tee -a "$LOG_FILE"
            echo "✅ Rosetta 2 installation completed."
        else
            echo -e "\n✅ Rosetta 2 is already installed."
            log_verbose "Rosetta 2 functional test passed successfully."
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

    # 4. Workstation Recipe Selection & Assembly
    echo -e "\n📦 Workstation Recipe Selection"
    BREWFILE_PATH="$HOME/Brewfile"
    
    # ---------------------------------------------------------
    # CORE BASELINE FETCH (Supports HTTP or Local Path)
    # ---------------------------------------------------------
    local core_target="$REPO_RECIPES_TARGET/core_brewfile.txt"
    log_verbose "Fetching core base from $core_target..."
    
    if ! fetch_core_with_fallback "$core_target" "$BREWFILE_PATH" "Core Base blueprint"; then
        return 1
    fi
    echo "✅ Core Base blueprint loaded."
    
    # ---------------------------------------------------------
    # OMNI-SELECTOR MENU
    # ---------------------------------------------------------
    run_omni_selector "brew" "$BREWFILE_PATH"

    # =========================================================================
    # CATALOG INJECTION: Append the master optional catalog (HTTP or Local)
    # =========================================================================
    log_verbose "Fetching master catalog from $CATALOG_TARGET..."
    echo -e "\n\n# =====================================================================" >> "$BREWFILE_PATH"
    echo "# 📚 MASTER CATALOG (Remove the '#' to install any optional software)" >> "$BREWFILE_PATH"
    echo "# =====================================================================" >> "$BREWFILE_PATH"
    
    append_catalog_with_fallback "$CATALOG_TARGET" "$BREWFILE_PATH" "Master Brew Catalog"

    # 5. Brewfile Review & Editing
    # Allows last-minute adjustments to the Brewfile before kicking off the long install process.
    if [[ -z "$SETUP_SKIP_BREWFILE_EDIT" ]]; then
        read "edit_brewfile?Would you like to review/edit the final Brewfile before installation? [y/N] "
        if [[ "$edit_brewfile" =~ ^[Yy]$ ]]; then
            editor=$(get_editor)
            echo "📝 Opening file in $editor..."
            eval "$editor \"$BREWFILE_PATH\""
            read "?Press [Enter] to continue with installation..."
        fi
    fi

    # 6. Brew Bundle Installation
    # Reads the Brewfile and installs all requested formulae, casks, and MAS apps.
    echo -e "\n⏳ Starting application installation process from Brewfile..."
    echo -e "⚠️  Note: Mac App Store (MAS) downloads do not show a progress bar in the terminal."
    echo -e "   To check download progress for MAS apps, open Launchpad or the App Store app."
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
    echo "🧹 Cleaning up Homebrew caches..."
    brew cleanup 2>&1 | tee -a "$LOG_FILE"
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
        log_verbose "Fetching gitignore from configured URL: $GITIGNORE_TARGET..."
        curl -fsSL "$GITIGNORE_TARGET" -o ~/.gitignore
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

    # 1. Strategy Selection
    echo -e "\n🐚 Shell & Terminal Configuration Strategy"
    echo "1. Standard Setup (Default: Oh My Zsh, P10k Theme, & Premium Plugins)"
    echo "2. Custom Setup (Step-by-step manual selection)"
    echo "3. Vanilla Zsh (Skip all frameworks and themes)"
    read "shell_strategy?Select an option [1-3]: "

    local INSTALL_OMZ=0
    local INSTALL_PLUGINS=0
    local INSTALL_P10K=0

    case "$shell_strategy" in
        2)
            read "opt_omz?Install Oh My Zsh framework? [Y/n] "
            [[ "${opt_omz:-Y}" =~ ^[Yy]$ ]] && INSTALL_OMZ=1
            
            read "opt_plugins?Install Premium Plugins (Autosuggestions, Syntax Highlighting, Zoxide)? [Y/n] "
            [[ "${opt_plugins:-Y}" =~ ^[Yy]$ ]] && INSTALL_PLUGINS=1
            
            read "opt_p10k?Install Powerlevel10k theme? [Y/n] "
            [[ "${opt_p10k:-Y}" =~ ^[Yy]$ ]] && INSTALL_P10K=1
            ;;
        3)
            echo "⏭️ Proceeding with Vanilla Zsh (No frameworks or themes)."
            ;;
        *)
            echo "✅ Proceeding with Standard Setup."
            INSTALL_OMZ=1
            INSTALL_PLUGINS=1
            INSTALL_P10K=1
            ;;
    esac

    # 2. Framework & Package Installation
    if [[ $INSTALL_OMZ -eq 1 ]]; then
        if [[ ! -d ~/.oh-my-zsh ]]; then
            echo -e "\n📦 Installing Oh My Zsh framework..."
            log_verbose "Running OMZ install script with RUNZSH=no..."
            RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 2>&1 | tee -a "$LOG_FILE"
        else
            echo -e "\n✅ Oh My Zsh is already installed."
        fi
    fi

    if [[ $INSTALL_P10K -eq 1 ]]; then
        echo -e "\n🎨 Installing Powerlevel10k theme via Homebrew..."
        brew install romkatv/powerlevel10k/powerlevel10k 2>&1 | tee -a "$LOG_FILE"
    fi

    if [[ $INSTALL_PLUGINS -eq 1 ]]; then
        echo -e "\n🔌 Installing shell plugins..."
        log_verbose "Installing zsh-syntax-highlighting via brew..."
        brew install zsh-syntax-highlighting 2>&1 | tee -a "$LOG_FILE"

        log_verbose "Cloning OMZ-native plugins..."
        [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" -q
        [[ ! -d "$ZSH_CUSTOM_DIR/plugins/z" ]] && git clone https://github.com/rupa/z.git "$ZSH_CUSTOM_DIR/plugins/z" -q

        # Update OMZ custom plugins if they already existed
        for plugin in "$ZSH_CUSTOM_DIR"/plugins/*/; do
            if [[ -d "$plugin/.git" ]]; then
                log_verbose "Git pulling latest for $(basename "$plugin")..."
                git -C "$plugin" pull -q
            fi
        done
    fi

    # 3. Backup & Profile Selection
    ZSHRC_PATH="$HOME/.zshrc"
    if [[ -f "$ZSHRC_PATH" ]]; then
        echo -e "\n💾 Backing up existing .zshrc..."
        mv "$ZSHRC_PATH" "$ZSHRC_PATH.bak.$(date +%Y%m%d_%H%M%S)"
    fi

    # The Omni-Selector now handles fetching the core profile OR overwriting it with a custom choice
    run_omni_selector "shell" "$ZSHRC_PATH"

    # 4. Dynamic System Injections  
    echo -e "\n💻 Applying dynamic environment hooks..."
    echo -e "\n# =====================================================================" >> "$ZSHRC_PATH"
    echo "# ⚡ DYNAMIC SYSTEM HOOKS (Auto-Generated by Brewmaster)" >> "$ZSHRC_PATH"
    echo "# =====================================================================" >> "$ZSHRC_PATH"

    HOMEBREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/opt/homebrew")

    if [[ $INSTALL_P10K -eq 1 ]]; then
        log_verbose "Injecting Powerlevel10k hook..."
        cat >> "$ZSHRC_PATH" << EOF

# Load Powerlevel10k Theme
source "$HOMEBREW_PREFIX/opt/powerlevel10k/powerlevel10k.zsh-theme"
EOF
        echo -e "\n🎨 Fetching Powerlevel10k Theme Configuration..."
        fetch_core_with_fallback "$REPO_P10K_TARGET" "$HOME/.p10k.zsh" "Powerlevel10k Config"
    fi

    if [[ $INSTALL_PLUGINS -eq 1 ]]; then
        log_verbose "Injecting syntax-highlighting hook..."
        cat >> "$ZSHRC_PATH" << EOF

# Load Homebrew zsh-syntax-highlighting
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
EOF
    fi

    # Universal Version Manager (mise) Hook
    if command -v mise &> /dev/null; then
        log_verbose "Injecting mise initialization string..."
        echo -e "\n# Initialize mise (Universal Version Manager)\neval \"\$(mise activate zsh)\"" >> "$ZSHRC_PATH"
    fi

    # Visual Studio Code Path Integration
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        log_verbose "Injecting VS Code binary path..."
        echo -e "\n# Add Visual Studio Code (code) command to PATH\nexport PATH=\"/Applications/Visual Studio Code.app/Contents/Resources/app/bin:\$PATH\"" >> "$ZSHRC_PATH"
    fi

    # 5. Mackup Restore (Legacy Application Settings)
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

    echo "✅ Shell profile assembly complete."
}

# =============================================================================
# PHASE 5: MACOS PREFERENCES
# =============================================================================
phase_macos() {
    print_header "Phase 5: macOS System & Development Preferences"

    PREFS_FILE_PATH="$HOME/.macos_prefs_manifest.toml"
    
    echo -e "\n⚙️ Fetching macOS Core Preferences..."
    
    # 1. Fetch Core Preferences
    if ! fetch_core_with_fallback "$PREFS_CORE_TARGET" "$PREFS_FILE_PATH" "Core Preferences blueprint"; then
        return 1
    fi
    echo "✅ Core preferences loaded."

    # 2. Call the Global Omni-Selector
    echo -e "\n📦 macOS Preference Recipe Selection"
    run_omni_selector "prefs" "$PREFS_FILE_PATH"

    # 3. Catalog Injection
    log_verbose "Fetching master prefs catalog from $PREFS_CATALOG_TARGET..."
    echo -e "\n\n# =====================================================================" >> "$PREFS_FILE_PATH"
    echo "# 📚 MASTER PREFS CATALOG (Remove the '#' to apply optional settings)" >> "$PREFS_FILE_PATH"
    echo "# =====================================================================" >> "$PREFS_FILE_PATH"
    
    append_catalog_with_fallback "$PREFS_CATALOG_TARGET" "$PREFS_FILE_PATH" "Master Prefs Catalog"

    # 4. Review & Edit
    if [[ -z "$SETUP_SKIP_PREFS_EDIT" ]]; then
        echo -e "\n📖 The macOS Preferences Manifest is ready."
        read "edit_prefs?Would you like to review/edit the preferences before applying? [Y/n] "
        if [[ "${edit_prefs:-Y}" =~ ^[Yy]$ ]]; then
            editor=$(get_editor)
            echo "📝 Opening file in $editor..."
            eval "$editor \"$PREFS_FILE_PATH\""
            read "?Press [Enter] to continue and apply preferences..."
        fi
    fi

    # 5. The Procedural Parser (Safe Execution Engine)
    echo -e "\n⏳ Applying selected macOS preferences..."
    
    local applied_count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip leading whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue
        
        # SECURITY GUARD: Only execute valid `defaults` commands
        if [[ "$line" == defaults* ]]; then
            log_verbose "Executing: $line"
            eval "$line" 
            ((applied_count++))
        else
            log_verbose "⚠️ Ignored invalid/unauthorized command: $line"
        fi
    done < "$PREFS_FILE_PATH"

    # 6. Interactive System Preferences
    echo -e "\n📸 Standalone Preferences"
    read "setup_screenshots?Would you like screenshots to automatically save to a 'Screenshots' folder on your Desktop? [Y/n] "
    # If setup_screenshots is empty (user hit Enter), substitute 'Y' as the default
    if [[ "${setup_screenshots:-Y}" =~ ^[Yy]$ ]]; then
        log_verbose "Creating ~/Desktop/Screenshots and updating defaults..."
        mkdir -p ~/Desktop/Screenshots
        defaults write com.apple.screencapture location ~/Desktop/Screenshots
        echo "✅ Screenshot location updated."
    fi

    # 7. Apply Changes & Cleanup
    echo "✅ $applied_count text-based preferences applied."
    echo "🔄 Restarting affected system UI processes..."
    log_verbose "Killing Finder, Dock, and SystemUIServer..."
    killall Finder Dock SystemUIServer 2>/dev/null || true
    
    # Cleanup the manifest file
    rm -f "$PREFS_FILE_PATH"
    
    
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

# Dynamic Powerlevel10k Wizard Check
HOMEBREW_PREFIX=$(brew --prefix 2>/dev/null || echo "/opt/homebrew")
if [[ -d "$HOMEBREW_PREFIX/opt/powerlevel10k" && ! -f "$HOME/.p10k.zsh" ]]; then
    echo -e "\033[1;36m5.\033[0m ⚡ Run \033[1;31mp10k configure\033[0m to run the terminal theme configuration wizard."
fi

echo -e "\n📑 \033[1;34mExecution log saved to:\033[0m $LOG_FILE"
echo -e "\n🎯 \033[1;33mYour modular development environment is now ready!\033[0m"

echo "--- Brewmaster Setup Completed: $(date) ---" >> "$LOG_FILE"

# Start a new zsh session to load all configurations
echo -e "\n🚀 Starting new shell session with updated configuration..."
exec zsh