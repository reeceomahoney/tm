# Dependency installation for macOS (Homebrew) and Linux (package manager + release binaries).

# tool:minimum-version. Tools below their minimum are (re)installed.
TM_TOOLS="tmux:3.3 nvim:0.11.2 lazygit:0.40 fzf:0.44 tree-sitter:0.25 rg: fd: node: git:"

tool_min() {
    local entry
    for entry in $TM_TOOLS; do
        [[ ${entry%%:*} == "$1" ]] && { echo "${entry#*:}"; return; }
    done
}

# True if the tool is installed and meets its minimum version.
tool_ok() {
    local min version
    min=$(tool_min "$1")
    has "$1" || return 1
    [[ -z $min ]] && return 0
    version=$(tool_version "$1")
    [[ -n $version ]] && version_ge "$version" "$min"
}

install_deps() {
    info "Installing dependencies ($TM_OS/$TM_ARCH)"
    mkdir -p "$TM_BIN_DIR" "$TM_OPT_DIR/bin"
    export PATH="$TM_BIN_DIR:$PATH"

    if [[ $TM_OS == darwin ]]; then
        deps_darwin
    else
        deps_linux
    fi
}

deps_darwin() {
    if ! xcode-select -p >/dev/null 2>&1; then
        warn "Xcode command line tools missing (needed for git and treesitter); launching installer"
        xcode-select --install || true
    fi

    if [[ -z $TM_PM ]]; then
        if confirm "Homebrew is not installed. Install it now?"; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            local brew
            for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                [[ -x $brew ]] && eval "$("$brew" shellenv)" && break
            done
            has brew || die "Homebrew install failed"
            TM_PM=brew
        else
            die "Homebrew is required on macOS (https://brew.sh)"
        fi
    fi

    local tool formula missing=()
    for tool in tmux nvim lazygit fzf tree-sitter rg fd node; do
        tool_ok "$tool" && { ok "$tool $(tool_version "$tool")"; continue; }
        case $tool in
            nvim)        formula=neovim ;;
            tree-sitter) formula=tree-sitter-cli ;;
            rg)          formula=ripgrep ;;
            *)           formula=$tool ;;
        esac
        missing+=("$formula")
    done

    if ((${#missing[@]})); then
        info "brew install ${missing[*]}"
        brew install "${missing[@]}"
        # Upgrade anything that was installed but too old.
        brew upgrade "${missing[@]}" 2>/dev/null || true
    fi
}

deps_linux() {
    # Packages from the system package manager: anything without a usable release binary.
    local cmd pkg missing=()
    for cmd in git curl tar unzip tmux rg fd cc make node npm; do
        has "$cmd" && continue
        [[ $cmd == fd ]] && has fdfind && continue
        pkg=$(linux_pkg "$cmd") || continue
        missing+=("$pkg")
    done

    if ((${#missing[@]})); then
        if [[ -z $TM_PM ]]; then
            warn "no supported package manager (apt/dnf/pacman); install manually: ${missing[*]}"
        elif [[ $TM_SUDO == none ]]; then
            warn "not root and no sudo; install manually: ${missing[*]}"
        else
            info "$TM_PM install ${missing[*]}"
            case $TM_PM in
                apt)
                    as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq &&
                        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
                    ;;
                dnf)    as_root dnf install -y -q "${missing[@]}" ;;
                pacman) as_root pacman -S --needed --noconfirm "${missing[@]}" ;;
            esac || warn "$TM_PM install failed; re-run 'tm setup' or install manually: ${missing[*]}"
        fi
    fi

    # Debian/Ubuntu ship fd as `fdfind`.
    if ! has fd && has fdfind; then
        ln -sf "$(command -v fdfind)" "$TM_BIN_DIR/fd"
    fi

    tool_ok tmux || warn "tmux $(tool_version tmux) is older than $(tool_min tmux); some settings may not apply"

    # Distro packages for these are usually too old, so pull official release binaries.
    local tool
    for tool in nvim lazygit fzf tree-sitter; do
        if tool_ok "$tool"; then
            ok "$tool $(tool_version "$tool")"
        else
            if ! "release_$(echo "$tool" | tr - _)"; then
                warn "failed to install $tool"
                continue
            fi
            hash -r
            tool_ok "$tool" && ok "$tool $(tool_version "$tool")" ||
                warn "$tool installed but $(command -v "$tool") reports '$(tool_version "$tool")'; check PATH order"
        fi
    done

    for tool in tmux rg fd node git; do
        has "$tool" && ok "$tool $(tool_version "$tool")" || warn "$tool missing"
    done
}

linux_pkg() {
    case $TM_PM:$1 in
        *:rg)        echo ripgrep ;;
        apt:fd)      echo fd-find ;;
        dnf:fd)      echo fd-find ;;
        *:fd)        echo fd ;;
        apt:cc)      echo build-essential ;;
        pacman:cc)   echo base-devel ;;
        *:cc)        echo gcc ;;
        apt:make | pacman:make) return 1 ;; # comes with build-essential / base-devel
        *:node)      echo nodejs ;;
        *)           echo "$1" ;;
    esac
}

# Latest release tag of a GitHub repo, without the leading "v". Uses the redirect, not the API (no rate limit).
latest_tag() {
    curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/v\{0,1\}##'
}

# download URL -> path of a fresh temp file
download() {
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/tm.XXXXXX")
    printf '  %sdownloading %s%s\n' "$_c_dim" "$1" "$_c_reset" >&2
    curl -fsSL "$1" -o "$tmp" || { rm -f "$tmp"; warn "download failed: $1"; return 1; }
    echo "$tmp"
}

link_bin() {
    ln -sf "$1" "$TM_BIN_DIR/$(basename "$1")"
}

release_nvim() {
    local tarball
    tarball=$(download "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$TM_ARCH.tar.gz") || return 1
    rm -rf "$TM_OPT_DIR/nvim"
    mkdir -p "$TM_OPT_DIR/nvim"
    tar -xzf "$tarball" -C "$TM_OPT_DIR/nvim" --strip-components=1 || return 1
    rm -f "$tarball"
    link_bin "$TM_OPT_DIR/nvim/bin/nvim"
}

release_lazygit() {
    local version tarball
    version=$(latest_tag jesseduffield/lazygit)
    tarball=$(download "https://github.com/jesseduffield/lazygit/releases/download/v$version/lazygit_${version}_linux_$TM_ARCH.tar.gz") || return 1
    tar -xzf "$tarball" -C "$TM_OPT_DIR/bin" lazygit || return 1
    rm -f "$tarball"
    link_bin "$TM_OPT_DIR/bin/lazygit"
}

release_fzf() {
    local version arch tarball
    version=$(latest_tag junegunn/fzf)
    [[ $TM_ARCH == x86_64 ]] && arch=amd64 || arch=arm64
    tarball=$(download "https://github.com/junegunn/fzf/releases/download/v$version/fzf-$version-linux_$arch.tar.gz") || return 1
    tar -xzf "$tarball" -C "$TM_OPT_DIR/bin" fzf || return 1
    rm -f "$tarball"
    link_bin "$TM_OPT_DIR/bin/fzf"
}

release_tree_sitter() {
    local arch gz
    [[ $TM_ARCH == x86_64 ]] && arch=x64 || arch=arm64
    gz=$(download "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$arch.gz") || return 1
    gunzip -c "$gz" >"$TM_OPT_DIR/bin/tree-sitter" || return 1
    chmod +x "$TM_OPT_DIR/bin/tree-sitter"
    rm -f "$gz"
    link_bin "$TM_OPT_DIR/bin/tree-sitter"
}
