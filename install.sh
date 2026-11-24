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

# --- Prerequisites (fresh Mac) ---

if ! xcode-select -p &> /dev/null; then
  echo "==> Xcode Command Line Tools are missing. Launching the installer..."
  xcode-select --install || true
  echo "    Finish the installer dialog, then re-run ./install.sh"
  exit 1
fi

if ! command -v brew &> /dev/null && [ ! -x /opt/homebrew/bin/brew ]; then
  echo "==> Installing Homebrew (will ask for your password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh-My-Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# --- Core tools (always installed) ---

# Install a cask without aborting when the app was already installed outside Homebrew
# (e.g. Ghostty from its website): adopt it into Homebrew, or skip with a warning.
install_cask() {
  local cask="$1"
  if brew list --cask "$cask" &> /dev/null; then
    echo "  $cask already installed via Homebrew"
  elif ! brew install --cask "$cask"; then
    echo "  $cask exists outside Homebrew; trying to adopt it..."
    brew install --cask --adopt "$cask" || echo "  WARNING: skipping $cask (already present, couldn't adopt)"
  fi
}

echo "==> Installing core Homebrew packages..."
install_cask ghostty
install_cask font-jetbrains-mono-nerd-font
brew install starship fzf eza ripgrep thefuck
# Agentic workflow: herdr multiplexes agent sessions; gh + jq are tools agents reach for constantly
brew install herdr gh jq

echo "==> Setting up fzf keybindings..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish

echo "==> Installing Oh-My-Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# --- Optional tools ---

if ask "Install Raycast (launcher)?"; then
  install_cask raycast
fi

if ask "Install the Herdr desktop app? (main herdr; hop and pstack-herdr target it)" y; then
  install_cask herdr-app
fi

INSTALL_TMUX=false
if ask "Install tmux? (herdr covers most of this; useful for SSH/remote boxes)"; then
  INSTALL_TMUX=true
  brew install tmux
fi

if ask "Install nvm + Node.js LTS?"; then
  echo "==> Setting up nvm and Node.js..."
  brew install nvm
  mkdir -p "$HOME/.nvm"
  export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
fi

if ask "Install rbenv + Ruby 3.2.2?"; then
  echo "==> Setting up rbenv and Ruby..."
  brew install rbenv
  eval "$(rbenv init - bash)"
  rbenv install 3.2.2 --skip-existing
  rbenv global 3.2.2
fi

if ask "Install Claude Code (+ herdr integration)?"; then
  if ! command -v claude &> /dev/null && [ ! -x "$HOME/.local/bin/claude" ]; then
    echo "==> Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | sh
  fi
  echo "==> Installing herdr's Claude Code hook (reports session identity to herdr)..."
  mkdir -p "$HOME/.claude"
  herdr integration install claude || echo "    (herdr integration failed; run 'herdr integration install claude' later)"

  if ask "Install the pstack plugin (Lauren Tan's agent skills) for Claude Code?" y; then
    claude plugin marketplace add cursor/plugins || true
    claude plugin install pstack@cursor-plugins || echo "    (pstack install failed; in Claude Code run /plugin install pstack@cursor-plugins)"
  fi
fi

# --- Local models: keep coding when Claude tokens run out ---

if ask "Set up local models (Ollama + opencode, ~14 GB download)?" y; then
  echo "==> Installing Ollama and opencode..."
  brew install ollama opencode
  brew services start ollama
  for _ in {1..20}; do curl -sf http://localhost:11434/api/tags > /dev/null && break; sleep 1; done
  echo "==> Pulling gpt-oss:20b and building gpt-oss-64k (64K context)..."
  ollama pull gpt-oss:20b
  ollama create gpt-oss-64k -f "$DOTFILES_DIR/ollama/Modelfile.gpt-oss-64k"
  herdr integration install opencode || echo "    (run 'herdr integration install opencode' later)"
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
  ln -sfn "$src" "$dest"
}

backup_and_link "$DOTFILES_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/dotfiles/.aliases" "$HOME/.aliases"
if [[ "$INSTALL_TMUX" == true ]]; then
  backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

mkdir -p "$HOME/.config/ghostty" "$HOME/.config/herdr"
backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
backup_and_link "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
backup_and_link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Link the opencode config file only: herdr writes its own plugins into ~/.config/opencode/
mkdir -p "$HOME/.config/opencode" "$HOME/.local/bin" "$HOME/.claude/skills"
backup_and_link "$DOTFILES_DIR/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
backup_and_link "$DOTFILES_DIR/bin/hop" "$HOME/.local/bin/hop"
backup_and_link "$DOTFILES_DIR/claude/skills/pstack-herdr" "$HOME/.claude/skills/pstack-herdr"
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
backup_and_link "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
touch "$HOME/.ssh/config.local" "$HOME/.gitignore_global"

# --- Git identity, SSH key, signed commits ---

SSH_KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$HOME/.gitconfig.local" ]; then
  echo "==> Git identity (saved to untracked ~/.gitconfig.local)"
  read -rp "  Name: " git_name
  read -rp "  Email: " git_email
  printf '[user]\n  name = %s\n  email = %s\n' "$git_name" "$git_email" > "$HOME/.gitconfig.local"
fi

if [ ! -f "$SSH_KEY" ] && ask "Generate an SSH key for this machine?" y; then
  ssh-keygen -t ed25519 -C "$(scutil --get ComputerName 2>/dev/null || hostname)" -f "$SSH_KEY"
fi

if [ -f "$SSH_KEY" ]; then
  # Passphrase goes in the macOS Keychain so agents can sign commits without a prompt
  ssh-add --apple-use-keychain "$SSH_KEY" || true

  if ! git config --file "$HOME/.gitconfig.local" --get user.signingkey &> /dev/null; then
    echo "==> Enabling SSH-signed commits..."
    git config --file "$HOME/.gitconfig.local" user.signingkey "$SSH_KEY.pub"
    git config --file "$HOME/.gitconfig.local" commit.gpgsign true
  fi

  if ask "Authenticate GitHub and upload this key (auth + signing) with gh?" y; then
    gh auth status &> /dev/null || gh auth login --hostname github.com --git-protocol ssh --web
    gh auth refresh --hostname github.com --scopes admin:ssh_signing_key
    gh ssh-key add "$SSH_KEY.pub" --type signing --title "$(scutil --get ComputerName 2>/dev/null || hostname) signing" \
      || echo "    (signing key upload failed or already exists)"
  fi

  # Lets `git log --show-signature` / `git verify-commit` check your own signatures locally
  git config --file "$HOME/.gitconfig.local" gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
  printf '%s %s\n' "$(git config --file "$HOME/.gitconfig.local" user.email)" "$(cat "$SSH_KEY.pub")" > "$HOME/.ssh/allowed_signers"
fi

# Trust GitHub's SSH host keys, fetched over authenticated HTTPS instead of trust-on-first-use
if gh auth status &> /dev/null && ! ssh-keygen -F github.com &> /dev/null; then
  echo "==> Adding GitHub SSH host keys to known_hosts..."
  gh api meta --jq '.ssh_keys[] | "github.com " + .' >> "$HOME/.ssh/known_hosts"
fi

echo "==> Done! Open the Herdr app (or Ghostty + herdr for the TUI) and run: source ~/.zshrc"
