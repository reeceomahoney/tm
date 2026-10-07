# Shared helpers. Sourced by bin/tm; must stay bash 3.2 compatible (macOS).

TM_BIN_DIR="${TM_BIN_DIR:-$HOME/.local/bin}"
TM_OPT_DIR="${TM_OPT_DIR:-$HOME/.local/share/tm-opt}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

if [[ -t 1 ]]; then
    _c_blue=$'\033[34m' _c_green=$'\033[32m' _c_yellow=$'\033[33m' _c_red=$'\033[31m' _c_dim=$'\033[2m' _c_reset=$'\033[0m'
else
    _c_blue='' _c_green='' _c_yellow='' _c_red='' _c_dim='' _c_reset=''
fi

info() { printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$_c_green" "$_c_reset" "$*"; }
warn() { printf '  %s!%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# Ask a yes/no question on the terminal, even when stdin is a curl pipe.
confirm() {
    [[ ${TM_YES:-0} == 1 ]] && return 0
    local reply
    if ! { exec 3</dev/tty; } 2>/dev/null; then
        return 1
    fi
    printf '%s [y/N] ' "$1" >/dev/tty
    read -r reply <&3
    exec 3<&-
    [[ $reply == [yY]* ]]
}

# version_ge A B -> true if A >= B (numeric dotted versions)
version_ge() {
    local IFS=.
    local -a a=($1) b=($2)
    local i x y
    for i in 0 1 2; do
        x=$((10#${a[i]:-0})) y=$((10#${b[i]:-0}))
        ((x > y)) && return 0
        ((x < y)) && return 1
    done
    return 0
}

# First dotted version number found in the input.
extract_version() {
    grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1
}

# Installed version of a tool, or empty if missing.
tool_version() {
    has "$1" || return 0
    case $1 in
        nvim)        nvim --version 2>/dev/null | head -n 1 | extract_version ;;
        tmux)        tmux -V 2>/dev/null | extract_version ;;
        lazygit)     lazygit --version 2>/dev/null | tr ',' '\n' | sed -n 's/^ *version=//p' ;;
        *)           "$1" --version 2>/dev/null | head -n 1 | extract_version ;;
    esac
}
