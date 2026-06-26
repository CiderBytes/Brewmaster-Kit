# =============================================================================
# 🐚 BREWMASTER WORKSTATION: CORE SHELL PROFILE
# =============================================================================

# --- 1. PRE-INITIALIZATION ---
# Run Fastfetch at login if installed
if command -v fastfetch &> /dev/null; then
    fastfetch -c all
fi

# Enable Powerlevel10k instant prompt (Must stay at the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 2. PATH & ENVIRONMENT ---
export PATH="/usr/local/bin:$HOME/bin:$PATH"
ZSH_DISABLE_COMPFIX=true

# --- 3. OH MY ZSH INITIALIZATION ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell" # Fallback theme

# Core Plugins
plugins=(
    1password
    brew
    colorize
    git
    macos
    sudo
    vscode
    web-search
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

# --- 6. APPLICATION INTEGRATIONS ---
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"