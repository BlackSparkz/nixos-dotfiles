#!/usr/bin/env bash

set -euo pipefail

log()  { printf '\e[1;34m=>\e[0m %s\n' "$*"; }
ok()   { printf '\e[1;32m✓\e[0m  %s\n' "$*"; }
warn() { printf '\e[1;33m!\e[0m  %s\n' "$*"; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

require() {
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
    done
}

# ── distro detection ──────────────────────────────────────────────────────────
[[ -r /etc/os-release ]] || die "/etc/os-release not found"
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}" in
  nixos) DISTRO=nixos ;;
  fedora) DISTRO=fedora ;;
  *)
    case " ${ID_LIKE:-} " in
      *" fedora "*) DISTRO=fedora ;;
      *) die "Unsupported distro: ${ID:-unknown} (supported: nixos, fedora)" ;;
    esac
    ;;
esac
log "Detected distro: ${DISTRO}"

# ── console font (TTY only) ───────────────────────────────────────────────────
if [[ -t 0 && "$(tty 2>/dev/null)" == /dev/tty* ]]; then
  setfont latarcyrheb-sun32 || warn "setfont failed, skipping"
else
  ok "Not in TTY, skipping font size..."
fi

# ── fedora package list (edit to taste) ───────────────────────────────────────
FEDORA_PKGS=(
  rfkill
  git
  fastfetch
  awww
  fish
  bat
  waybar
  tree
  os-prober
  cava
  rofi
  ffmpeg
  hyprlock
  libnotify
  mako
  python3
  android-tools
  cliphist
  mpv
  wl-clipboard
  slurp
  grim
  efibootmgr
  nwg-look
  thunar
  foot
  stow
  eza
  yazi
  bluez
  bluez-tools
  playerctl
  librewolf
  wlogout
  btop
  brightnessctl
  gh
  localsend
  alacritty
  fontconfig
)

DOTFILES="${HOME}/nixos-dotfiles"
NIXOS_DIR="${DOTFILES}/NixOS"
SYSTEM_NIXOS="/etc/nixos"

# ── preflight ─────────────────────────────────────────────────────────────────
if [[ "${DISTRO}" == nixos ]]; then
  require git stow rfkill nix nixos-rebuild
else
  require sudo dnf
  log "Installing packages via dnf"
  sudo dnf install --skip-unavailable -y "${FEDORA_PKGS[@]}"
  ok "Packages installed"
  require git stow rfkill
fi

[[ -d "${DOTFILES}" ]] || die "Dotfiles directory not found: ${DOTFILES}"

# ── NixOS: link system config ─────────────────────────────────────────────────
if [[ "${DISTRO}" == nixos ]]; then
  if [[ -f ${SYSTEM_NIXOS}/hardware-configuration.nix && ! -L ${SYSTEM_NIXOS}/hardware-configuration.nix ]]; then
    sudo mv "${SYSTEM_NIXOS}/hardware-configuration.nix" "${NIXOS_DIR}/hardware-configuration.nix"
  fi

  if [[ ! -L ${SYSTEM_NIXOS}/hardware-configuration.nix ]]; then
    sudo ln -s "${NIXOS_DIR}/hardware-configuration.nix" "${SYSTEM_NIXOS}/hardware-configuration.nix"
  else
    ok "Hardware-configuration Symlink exists"
  fi

  if [[ -f ${SYSTEM_NIXOS}/configuration.nix && ! -L ${SYSTEM_NIXOS}/configuration.nix ]]; then
    sudo rm -rf "${SYSTEM_NIXOS}/configuration.nix"
  fi
  if [[ ! -L ${SYSTEM_NIXOS}/configuration.nix ]]; then
    sudo ln -s "${NIXOS_DIR}/configuration.nix" "${SYSTEM_NIXOS}/configuration.nix"
  else
    ok "Configuration Symlink exists"
  fi
  ok "NixOS configuration completed"
fi

# ── stow configs ──────────────────────────────────────────────────────────────
log "Stowing Configs → ~/.config"
mkdir -p "${HOME}/.config"
cd "${DOTFILES}"
if ! stow --simulate -t "${HOME}/.config" Configs &>/dev/null; then
    die "stow reports conflicts — run 'stow --simulate -t ~/.config Configs' to inspect"
fi
stow --restow -t "${HOME}/.config" Configs
ok "Stow complete"

# ── fonts, wallpapers, icons ──────────────────────────────────────────────────
log "Installing fonts"
mkdir -p "${HOME}/.local/share/fonts"
cp -r -- "${DOTFILES}/Configs/Resources/fonts/." "${HOME}/.local/share/fonts/"
fc-cache -f "${HOME}/.local/share/fonts" || true
ok "Fonts installed"

log "Installing wallpapers"
cp -r -- "${DOTFILES}/Configs/Resources/Wallpapers" "${HOME}/"
ok "Wallpapers copied"

log "Installing cursor theme"
mkdir -p "${HOME}/.local/share/icons"
cp -r -- "${DOTFILES}/Configs/Resources/Bibata-Modern-Ice" "${HOME}/.local/share/icons/"
ok "Cursor theme installed"

# ── bluetooth ─────────────────────────────────────────────────────────────────
log "Unblocking bluetooth"
sudo rfkill unblock bluetooth
ok "Bluetooth unblocked"

# ── system apply ──────────────────────────────────────────────────────────────
if [[ "${DISTRO}" == nixos ]]; then
  log "Rebuilding NixOS"
  sudo nixos-rebuild switch
  ok "NixOS rebuild complete"
fi

ok "Install complete"
