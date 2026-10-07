# tm

A tmux sessionizer (inspired by ThePrimeagen's) that also sets up my full terminal
environment (tmux, neovim/LazyVim, lazygit, fzf) on a fresh macOS or Linux machine.

```sh
curl -fsSL https://raw.githubusercontent.com/reeceomahoney/tm/main/install.sh | sh
```

Options are passed through to `tm setup`:

```sh
curl -fsSL https://raw.githubusercontent.com/reeceomahoney/tm/main/install.sh | sh -s -- --no-deps
```

## Usage

```
tm                 pick a project directory or running session with fzf
tm <dir>           open <dir> as a tmux session
tm setup           install dependencies and link configs (safe to re-run)
                     --no-deps --no-configs --isolated --yes
tm update          git pull, then re-run setup
tm doctor          show tool versions and config status
tm uninstall       remove config links, restore backups
```

Search roots are configured in `~/.config/tm/config.sh` (plain bash):

```bash
TM_ROOTS=("$HOME/work" "$HOME/code")
TM_MIN_DEPTH=1
TM_MAX_DEPTH=1
TM_EXTRA=("$HOME/.dotfiles")
```

Defaults match the original script: every directory exactly two levels below `~`.

## What setup does

| | macOS | Linux |
|---|---|---|
| tmux, ripgrep, fd, node, compiler | Homebrew | apt / dnf / pacman |
| neovim, lazygit, fzf, tree-sitter | Homebrew | latest GitHub release → `~/.local/bin` |

Tools that are already installed and new enough are skipped. Then:

- `~/.config/tmux` and `~/.config/nvim` are symlinked to `config/` in this repo
  (existing ones are moved to `*.bak.<timestamp>`), so editing your config edits the repo.
- Neovim plugins are installed at the versions pinned in `lazy-lock.json`.
- `--isolated` links nvim as `~/.config/tm-nvim` instead; run it with `NVIM_APPNAME=tm-nvim nvim`.

Install location is `~/.local/share/tm` (`TM_HOME`); pin a version with `TM_VERSION=<tag>`.

## Layout

```
install.sh       curl | sh entrypoint: clone, then `tm setup`
bin/tm           the CLI
lib/             platform detection, dependency install, config linking
config/tmux      tmux.conf
config/nvim      LazyVim config
```
