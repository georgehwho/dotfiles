#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing Homebrew packages..."
brew install --cask ghostty
brew install --cask font-jetbrains-mono-nerd-font
brew install starship tmux fzf eza ripgrep thefuck nvm rbenv

echo "==> Setting up nvm and Node.js..."
mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
nvm install --lts
nvm alias default lts/*

echo "==> Setting up rbenv and Ruby..."
eval "$(rbenv init - bash)"
rbenv install 3.2.2 --skip-existing
rbenv global 3.2.2

echo "==> Installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | sh

echo "==> Setting up fzf keybindings..."
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

echo "==> Installing Oh-My-Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

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
