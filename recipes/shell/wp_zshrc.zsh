# =============================================================================
# 💻 BREWMASTER WORKSTATION: WORDPRESS DEVELOPER PROFILE
# =============================================================================

# --- 1. PRE-INITIALIZATION ---
if command -v fastfetch &> /dev/null; then
    fastfetch -c all
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 2. PATH & ENVIRONMENT ---
export PATH="/usr/local/bin:$HOME/bin:$PATH"
ZSH_DISABLE_COMPFIX=true

# --- 3. OH MY ZSH INITIALIZATION ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Expanded WordPress & Web Dev Plugins
plugins=(
    1password
    brew
    colorize
    composer         # Added for PHP dependency management
    git
    macos
    node             # Added for theme build scripts (NPM/Webpack/Vite)
    sudo
    vscode
    web-search
    wp-cli           # Added for native WP-CLI tab-completions
    z
    zsh-autosuggestions
)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# --- 4. SYSTEM COMPLETIONS ---
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  autoload -Uz compinit && compinit
fi

# --- 5. CORE ALIASES ---
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias buou="brew update && brew outdated && brew upgrade && brew cleanup"
alias reload="source ~/.zshrc && echo '⚡ Shell profile reloaded successfully.'"
alias ll="ls -lAhF"

# --- 6. WORDPRESS & WEB DEV ALIASES ---
# WP-CLI Shortcuts
alias wpflush="wp cache flush"
alias wpupdate="wp core update && wp plugin update --all && wp theme update --all"
alias wpdbexport="wp db export database_backup_$(date +%Y%m%d).sql"
alias wpsr="wp search-replace"

# Theme/Plugin Dev Shortcuts
alias dev="npm run dev"
alias build="npm run build"
alias art="php artisan" # Useful if working with Roots Sage/Bedrock or Laravel mix-ins

# Server/Local Env Utilities
alias php-error="tail -f /var/log/php_errors.log" # Adjust path based on local env (MAMP/Valet/etc)
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder && echo '🧹 macOS DNS Cache Flushed.'"

# --- 7. APPLICATION INTEGRATIONS ---
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"