#!/bin/sh
# tm installer.
#
#   curl -fsSL https://raw.githubusercontent.com/reeceomahoney/tm/main/install.sh | sh
#   curl -fsSL ... | sh -s -- --no-deps          # options are passed to `tm setup`
#
# Environment:
#   TM_HOME     install location        (default ~/.local/share/tm)
#   TM_VERSION  branch or tag to install (default main)
#   TM_REPO     git URL                 (default https://github.com/reeceomahoney/tm.git)

set -eu

TM_HOME="${TM_HOME:-$HOME/.local/share/tm}"
TM_VERSION="${TM_VERSION:-main}"
TM_REPO="${TM_REPO:-https://github.com/reeceomahoney/tm.git}"

say() { printf '\033[34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

case "$(uname -s)" in
    Darwin | Linux) ;;
    *) die "tm supports macOS and Linux only" ;;
esac

command -v bash >/dev/null 2>&1 || die "bash is required"
command -v curl >/dev/null 2>&1 || die "curl is required"
if ! command -v git >/dev/null 2>&1; then
    if [ "$(uname -s)" = Darwin ]; then
        die "git is required: run 'xcode-select --install', then re-run this installer"
    fi
    die "git is required: install it with your package manager (e.g. sudo apt install git), then re-run"
fi

if [ -d "$TM_HOME/.git" ]; then
    say "Updating $TM_HOME"
    git -C "$TM_HOME" pull -q --ff-only
else
    [ -e "$TM_HOME" ] && die "$TM_HOME exists and is not a git checkout; move it aside first"
    say "Cloning tm into $TM_HOME"
    git clone -q --depth 1 --branch "$TM_VERSION" "$TM_REPO" "$TM_HOME"
fi

# stdin is the curl pipe; give setup the terminal so prompts (sudo, Homebrew) work.
if [ -r /dev/tty ] && (exec </dev/tty) 2>/dev/null; then
    exec bash "$TM_HOME/bin/tm" setup "$@" </dev/tty
fi
exec bash "$TM_HOME/bin/tm" setup "$@"
