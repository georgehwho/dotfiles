# George's Dotfiles

Terminal setup for agentic development on macOS, built around Ghostty + herdr + Starship + fzf.

## What's included

```
dotfiles/
  .zshrc          # Shell config (Oh-My-Zsh + Starship, no P10k)
  .aliases        # Git aliases, eza, ripgrep, thefuck, navigation shortcuts
ghostty/
  config          # Catppuccin Mocha, JetBrains Mono Nerd Font
git/
  .gitconfig      # SSH signing, sane defaults; identity in ~/.gitconfig.local
herdr/
  config.toml     # Agent multiplexer: Ctrl+a prefix, catppuccin theme
bin/
  hop             # Open Claude Code / opencode (local or hosted model) in a new herdr pane
claude/skills/
  pstack-herdr/   # pstack's parallel workers as herdr panes, mixed model families
ollama/
  Modelfile.gpt-oss-64k  # Local fallback model with a usable context window
opencode/
  opencode.jsonc  # opencode defaults to the local model
ssh/
  config          # Keychain-backed GitHub key; hosts in ~/.ssh/config.local
starship/
  starship.toml   # Prompt with git, k8s, aws, terraform, node, ruby modules
tmux/
  .tmux.conf      # Optional: Ctrl+a prefix, mouse, catppuccin status bar, Ghostty true color
```

## Installation

On a fresh Mac, install the Xcode Command Line Tools first (`xcode-select --install`) so `git` works. Then:

```bash
git clone https://github.com/georgehwho/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script will always install:
- Homebrew and Oh-My-Zsh, if they're missing
- Ghostty, herdr, Starship, fzf, eza, ripgrep, thefuck, gh, jq, and JetBrains Mono Nerd Font via Homebrew
- fzf keybindings and completion
- Oh-My-Zsh plugins (zsh-syntax-highlighting, zsh-autosuggestions)
- Symlinks for all config files (existing files are backed up to `~/.dotfiles_backup/<timestamp>/`)

You'll be prompted to optionally install:
- **Raycast**: launcher
- **herdr desktop app** (`herdr-app`): native GUI for herdr; still early, and the herdr CLI is installed regardless
- **tmux**: herdr covers local multiplexing; tmux is still handy on SSH/remote boxes
- **nvm + Node.js LTS**: if you do JavaScript/TypeScript work
- **rbenv + Ruby 3.2.2**: if you do Ruby work
- **Claude Code**: Anthropic's CLI for Claude, plus `herdr integration install claude` (a SessionStart hook in `~/.claude/settings.json` that reports session identity to herdr)

To skip the prompts and install everything, run:

```bash
./install.sh --all
```

## Using the Ghostty stack

**Ghostty** is the terminal emulator. Config lives at `~/.config/ghostty/config`.
- Native splits: `Cmd+D` (horizontal), `Cmd+Shift+D` (vertical)
- Navigate splits: `Cmd+[` / `Cmd+]`
- Config is file-based, no menus to click through

**herdr** is the agent multiplexer: workspaces and tiled panes, with each agent shown as working, idle or blocked. Config lives at `~/.config/herdr/config.toml`.
- Prefix is `Ctrl+a` (same as tmux, overriding herdr's default `Ctrl+b`)
- `herdr` starts or reattaches; `prefix q` detaches
- Full keymap: https://herdr.dev/docs/keyboard/

**Agent-safe shell**: when `CLAUDECODE` is set, `.aliases` skips the `ls→eza` and `grep→rg` overrides so agents get standard tools. Project-local `./bin` and `./node_modules/.bin` come *last* on PATH, so a repo an agent clones can't override `git`, `ls`, etc.

## Agents: Claude Code, local models, pstack

**Out of Claude tokens?** Keep going on a local model (free, offline):

| Command | What it does |
| --- | --- |
| `claude-local` | The same Claude Code (CLAUDE.md, skills, pstack, herdr hook) pointed at Ollama's `gpt-oss-64k`. Takes normal `claude` args, e.g. `claude-local --continue`. |
| `hop -k claude -m local` | The same thing, in a new herdr pane next to this one |
| `hop` | opencode on the local model in a new herdr pane |
| `hop -m deepseek -n reviewer` | opencode on the free hosted DeepSeek V4.1 Flash (not local, but free) |

The local model is **gpt-oss 20B** (`ollama/Modelfile.gpt-oss-64k` gives it a 64K context; Ollama's default on 24 GB is only 4K). It's the largest model that leaves room for context and other apps on a 24 GB Mac. Kimi and DeepSeek are far too large to run locally. Expect it to be noticeably weaker than Claude: good for continuing well-scoped work, not for hard design calls. Run one local session at a time.

**pstack** ([Lauren Tan's agent skills](https://github.com/cursor/plugins/tree/main/pstack)) is installed as a Claude Code plugin; its commands are `/pstack:<name>`, starting with `/pstack:setup-pstack`. **`claude/skills/pstack-herdr`** is the herdr flavor: inside herdr, pstack's parallel workers (swarm, arena, review panels) run as visible panes, each writer in its own git worktree, with at least one non-Claude (opencode) reviewer per panel.

**tmux** (optional) is for session persistence on remote machines (detach/reattach over SSH).
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

## Terragrunt / Terraform caching

`.zshrc` sets two env vars that keep Terraform/Terragrunt caches from clogging your repos and your editor:

- **`TERRAGRUNT_DOWNLOAD="$HOME/.cache/terragrunt"`** — Terragrunt copies each unit's module into a working directory (with generated backend/provider config) before running Terraform. By default that's an in-repo `.terragrunt-cache/` **per unit**, so a repo with hundreds of units accumulates hundreds of copies. Worse, editor language servers (VS Code's `terraform-ls`) index every one and can balloon to tens of GB of RAM. This relocates all caches to `~/.cache/terragrunt`, namespaced per unit — repos stay clean and the language server has nothing in-workspace to choke on.
- **`TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"`** — shares downloaded provider binaries across all units/repos instead of re-downloading them into every cache.

Both directories are created on shell startup, so this works on a fresh machine with no extra steps.

**If you use VS Code's Terraform extension**, also add to your workspace or user `settings.json` so `terraform-ls` never indexes stray caches:

```jsonc
"terraform.languageServer.indexing.ignorePaths": ["**/.terragrunt-cache"],
"files.watcherExclude": { "**/.terragrunt-cache/**": true }
```

**Clean up stray in-repo caches** (from before this was set, or a repo that overrides the download dir):

```bash
find . -type d -name .terragrunt-cache -prune -exec rm -rf {} +
```

## Git, SSH keys and signed commits

`install.sh` links `git/.gitconfig` → `~/.gitconfig` and `ssh/config` → `~/.ssh/config`, then:

1. Asks for your name/email and writes them to `~/.gitconfig.local` (untracked; included by `.gitconfig`)
2. Offers to generate `~/.ssh/id_ed25519` (one key per machine, so a lost laptop means revoking one key) and stores its passphrase in the macOS Keychain, so agents can sign without a prompt
3. Turns on SSH commit signing (`commit.gpgsign`) only once the key exists, so a fresh machine can always commit
4. Offers `gh auth login` plus uploading the key as a GitHub **signing** key, so commits show as Verified

Machine-specific SSH hosts go in `~/.ssh/config.local` (untracked).

## Secrets

Tokens and API keys go in `~/.env.secrets` (not tracked by git). The `.zshrc` sources it automatically if present.

## Post-install

If you have machine-specific config (work aliases, extra PATH entries, etc.), add them to `~/.zshrc.local` which is automatically sourced by `.zshrc` if present. Tokens and API keys should go in `~/.env.secrets` instead (also auto-sourced). Neither file is tracked by git.
