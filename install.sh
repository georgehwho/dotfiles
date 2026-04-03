#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Helpers ---

ask() {
  local prompt="$1" default="${2:-n}"
  if [[ "$INSTALL_ALL" == true ]]; then
    return 0
  fi
  if [[ "$default" == "y" ]]; then
    read -rp "$prompt [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
  else
    read -rp "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy] ]]
  fi
}

INSTALL_ALL=false
if [[ "$1" == "--all" ]]; then
  INSTALL_ALL=true
fi

# --- Core tools (always installed) ---

echo "==> Installing core Homebrew packages..."
brew install --cask ghostty
brew install --cask font-jetbrains-mono-nerd-font
brew install starship tmux fzf eza ripgrep thefuck

echo "==> Setting up fzf keybindings..."
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

echo "==> Installing Oh-My-Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# --- Optional tools ---

if ask "Install nvm + Node.js LTS?"; then
  echo "==> Setting up nvm and Node.js..."
  brew install nvm
  mkdir -p "$HOME/.nvm"
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  nvm install --lts
  nvm alias default lts/*
fi

if ask "Install rbenv + Ruby 3.2.2?"; then
  echo "==> Setting up rbenv and Ruby..."
  brew install rbenv
  eval "$(rbenv init - bash)"
  rbenv install 3.2.2 --skip-existing
  rbenv global 3.2.2
fi

if ask "Install Claude Code?"; then
  echo "==> Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | sh
fi

# --- Symlink dotfiles ---

echo "==> Symlinking dotfiles..."
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

backup_and_link() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "  Backing up $dest -> $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi
  ln -sf "$src" "$dest"
}

backup_and_link "$DOTFILES_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/dotfiles/.aliases" "$HOME/.aliases"
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.config/ghostty"
backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

echo "==> Done! Open Ghostty and run: source ~/.zshrc"
