# Homebrew first, so everything below (plugins, aliases, `command -v` checks) can see brew tools
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# (MacOS only) Prevent Homebrew from reporting
export HOMEBREW_NO_ANALYTICS=1

export ZSH="$HOME/.oh-my-zsh"

# Disable Oh-My-Zsh theme — Starship handles the prompt
ZSH_THEME=""

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# Docker completions (added before Oh-My-Zsh so its single compinit picks them up)
fpath=($HOME/.docker/completions $fpath)

# load Oh-My-Zsh
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# PATH
# Project-local bins go at the END: agents cd into arbitrary repos, and a repo's
# ./bin/git or ./node_modules/.bin/ls must never shadow the real tool.
export PATH="$HOME/.local/bin:$HOME/.rbenv/bin:${PATH}:/usr/local/sbin:$HOME/.docker/bin:./bin:./node_modules/.bin"

# Source secrets from a separate file (tokens, API keys, etc.)
# Create ~/.env.secrets for tokens you don't want in version control
[[ -f "$HOME/.env.secrets" ]] && source "$HOME/.env.secrets"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Lazy-load thefuck (saves ~300ms startup time)
if command -v thefuck &> /dev/null; then
  fuck() {
    unset -f fuck
    eval $(thefuck --alias)
    fuck "$@"
  }
fi

command -v rbenv &> /dev/null && eval "$(rbenv init - zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# nvm (node version manager)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Terragrunt / Terraform caching (see README "Terragrunt / Terraform caching")
# Keep per-unit module caches out of repos and share provider binaries across units.
export TERRAGRUNT_DOWNLOAD="$HOME/.cache/terragrunt"
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TERRAGRUNT_DOWNLOAD" "$TF_PLUGIN_CACHE_DIR"

# Starship prompt (must be last)
command -v starship &> /dev/null && eval "$(starship init zsh)"
