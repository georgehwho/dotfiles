export ZSH="$HOME/.oh-my-zsh"

# Disable Oh-My-Zsh theme — Starship handles the prompt
ZSH_THEME=""

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# (MacOS only) Prevent Homebrew from reporting
export HOMEBREW_NO_ANALYTICS=1

# load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.local/bin:./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"
export PATH="$HOME/.rbenv/bin:$PATH"

# Source secrets from a separate file (tokens, API keys, etc.)
# Create ~/.env.secrets for tokens you don't want in version control
[[ -f "$HOME/.env.secrets" ]] && source "$HOME/.env.secrets"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Aliases
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

eval $(/opt/homebrew/bin/brew shellenv)

# Lazy-load thefuck (saves ~300ms startup time)
if command -v thefuck &> /dev/null; then
  fuck() {
    unset -f fuck
    eval $(thefuck --alias)
    fuck "$@"
  }
fi

eval "$(rbenv init - zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Docker
export PATH=$PATH:~/.docker/bin
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit

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
eval "$(starship init zsh)"
