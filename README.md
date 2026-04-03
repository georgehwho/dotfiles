# George's Dotfiles

Terminal setup built around Ghostty + Starship + tmux + fzf on macOS.

## What's included

```
dotfiles/
  .zshrc          # Shell config (Oh-My-Zsh + Starship, no P10k)
  .aliases        # Git aliases, eza, ripgrep, thefuck, navigation shortcuts
ghostty/
  config          # Catppuccin Mocha, JetBrains Mono Nerd Font
starship/
  starship.toml   # Prompt with git, k8s, aws, terraform, node, ruby modules
tmux/
  .tmux.conf      # Ctrl+a prefix, mouse, catppuccin status bar, Ghostty true color
```

## Installation

```bash
git clone https://github.com/georgehwho/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script will always install:
- Ghostty, Starship, tmux, fzf, eza, ripgrep, thefuck, and JetBrains Mono Nerd Font via Homebrew
- fzf keybindings and completion
- Oh-My-Zsh plugins (zsh-syntax-highlighting, zsh-autosuggestions)
- Symlinks for all config files (existing files are backed up to `~/.dotfiles_backup/<timestamp>/`)

You'll be prompted to optionally install:
- **nvm + Node.js LTS** — if you do JavaScript/TypeScript work
- **rbenv + Ruby 3.2.2** — if you do Ruby work
- **Claude Code** — Anthropic's CLI for Claude

To skip the prompts and install everything, run:

```bash
./install.sh --all
```

## Using the Ghostty stack

**Ghostty** is the terminal emulator. Config lives at `~/.config/ghostty/config`.
- Native splits: `Cmd+D` (horizontal), `Cmd+Shift+D` (vertical)
- Navigate splits: `Cmd+[` / `Cmd+]`
- Config is file-based, no menus to click through

**tmux** is for session persistence (detach/reattach across terminal restarts).
- Prefix is `Ctrl+a` (not the default `Ctrl+b`)
- `Ctrl+a |` split horizontal, `Ctrl+a -` split vertical
- `Ctrl+a d` detach, then `tmux attach` to come back
- Mouse support is on for scrolling and pane resizing

**Starship** handles the prompt. Modules auto-detect context:
- Git branch/status always shown
- K8s context shown when `KUBECONFIG` is set
- AWS profile shown when active
- Terraform workspace shown in terraform dirs
- Node/Ruby versions shown in relevant project dirs

**fzf** gives fuzzy search everywhere:
- `Ctrl+R` for history search
- `Ctrl+T` for file search, `Alt+C` for directory jump

**Docker** is configured in `.zshrc` with `~/.docker/bin` on PATH and shell completions enabled.

## Secrets

Tokens and API keys go in `~/.env.secrets` (not tracked by git). The `.zshrc` sources it automatically if present.

## Post-install

If you have machine-specific config (work aliases, extra PATH entries, etc.), add them to `~/.zshrc.local` which is automatically sourced by `.zshrc` if present. Tokens and API keys should go in `~/.env.secrets` instead (also auto-sourced). Neither file is tracked by git.
