# OS / arch / package manager detection.

detect_platform() {
    case "$(uname -s)" in
        Darwin) TM_OS=darwin ;;
        Linux)  TM_OS=linux ;;
        *)      die "unsupported OS: $(uname -s)" ;;
    esac

    case "$(uname -m)" in
        x86_64 | amd64)  TM_ARCH=x86_64 ;;
        arm64 | aarch64) TM_ARCH=arm64 ;;
        *)               die "unsupported architecture: $(uname -m)" ;;
    esac

    TM_PM=
    if [[ $TM_OS == darwin ]]; then
        has brew && TM_PM=brew
    elif has apt-get; then
        TM_PM=apt
    elif has dnf; then
        TM_PM=dnf
    elif has pacman; then
        TM_PM=pacman
    fi

    # How to get root for package installs: nothing if already root, sudo if available.
    if [[ $(id -u) == 0 ]]; then
        TM_SUDO=
    elif has sudo; then
        TM_SUDO=sudo
    else
        TM_SUDO=none
    fi
}

as_root() {
    if [[ $TM_SUDO == none ]]; then
        return 1
    fi
    $TM_SUDO "$@"
}
