# Link the bundled tmux and nvim configs into ~/.config, backing up whatever was there.

# Destinations tm may own, for doctor/uninstall.
tm_config_dests() {
    echo "$XDG_CONFIG_HOME/tmux"
    echo "$XDG_CONFIG_HOME/nvim"
    echo "$XDG_CONFIG_HOME/tm-nvim"
}

# link_config SRC DEST: make DEST a symlink to SRC, moving any existing DEST aside.
link_config() {
    local src=$1 dest=$2 backup
    if [[ -L $dest && $(readlink "$dest") == "$src" ]]; then
        ok "$dest"
        return
    fi
    if [[ -e $dest || -L $dest ]]; then
        backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dest" "$backup"
        warn "moved existing $dest -> $backup"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    ok "$dest -> $src"
}

install_configs() {
    info "Linking configs"
    link_config "$TM_HOME/config/tmux" "$XDG_CONFIG_HOME/tmux"

    # tmux reads ~/.tmux.conf before ~/.config/tmux, so a stray one would shadow ours.
    if [[ -e $HOME/.tmux.conf || -L $HOME/.tmux.conf ]]; then
        local backup="$HOME/.tmux.conf.bak.$(date +%Y%m%d%H%M%S)"
        mv "$HOME/.tmux.conf" "$backup"
        warn "moved ~/.tmux.conf -> $backup"
    fi

    local appname=nvim
    if [[ ${TM_ISOLATED:-0} == 1 ]]; then
        appname=tm-nvim
        warn "isolated mode: use NVIM_APPNAME=tm-nvim nvim (e.g. alias vim='NVIM_APPNAME=tm-nvim nvim')"
    fi
    link_config "$TM_HOME/config/nvim" "$XDG_CONFIG_HOME/$appname"

    if has nvim; then
        info "Installing neovim plugins (lazy-lock.json)"
        # Twice: if lazy.nvim itself moves, the first pass only restores lazy.nvim
        # and then rewrites the lockfile from the stale plugin checkouts.
        NVIM_APPNAME=$appname nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 &&
            NVIM_APPNAME=$appname nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 &&
            ok "plugins restored" ||
            warn "plugin restore failed; open nvim and run :Lazy restore"
    fi

    if [[ -n ${TMUX:-} ]]; then
        tmux source-file "$XDG_CONFIG_HOME/tmux/tmux.conf" 2>/dev/null && ok "reloaded tmux config"
    fi
}

# Remove links into $TM_HOME and restore the newest backup for each.
uninstall_configs() {
    local dest backup
    for dest in $(tm_config_dests); do
        [[ -L $dest && $(readlink "$dest") == "$TM_HOME"/* ]] || continue
        rm "$dest"
        ok "removed $dest"
        backup=$(ls -1d "$dest".bak.* 2>/dev/null | sort | tail -n 1)
        if [[ -n $backup ]]; then
            mv "$backup" "$dest"
            ok "restored $backup"
        fi
    done
}
