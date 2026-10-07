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
