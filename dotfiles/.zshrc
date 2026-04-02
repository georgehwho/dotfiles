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
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

# Source secrets from a separate file (tokens, API keys, etc.)
# Create ~/.env.secrets for tokens you don't want in version control
[[ -f "$HOME/.env.secrets" ]] && source "$HOME/.env.secrets"

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

# Starship prompt (must be last)
eval "$(starship init zsh)"
