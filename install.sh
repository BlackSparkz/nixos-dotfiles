#!/usr/bin/env bash
set -euo pipefail

# ── helpers ────────────────────────────────────────────────────────────────────
log()  { printf '\e[1;34m=>\e[0m %s\n' "$*"; }
ok()   { printf '\e[1;32m✓\e[0m  %s\n' "$*"; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

require() {
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
    done
}

# ── preflight ──────────────────────────────────────────────────────────────────
require git stow rfkill nix nixos-rebuild

DOTFILES="${HOME}/nixos-dotfiles"
NIXOS_DIR="${DOTFILES}/NixOS"
SYSTEM_NIXOS="/etc/nixos"

[[ -d "${DOTFILES}" ]] || die "Dotfiles directory not found: ${DOTFILES}"

if [[ -f ${SYSTEM_NIXOS}/hardware-configuration.nix && ! -L ${SYSTEM_NIXOS}/hardware-configuration.nix ]]; then
  sudo mv "${SYSTEM_NIXOS}/hardware-configuration.nix" "${NIXOS_DIR}/hardware-configuration.nix"
fi

if [[ ! -L ${SYSTEM_NIXOS}/hardware-configuration.nix ]]; then 
  sudo ln -s "${NIXOS_DIR}/hardware-configuration.nix" "${SYSTEM_NIXOS}/hardware-configuration.nix"
else
  ok "Symlink exists"
fi

if [[ -f ${SYSTEM_NIXOS}/configuration.nix && ! -L ${SYSTEM_NIXOS}/configuration.nix ]]; then
  sudo mv "${SYSTEM_NIXOS}/configuration.nix" "${SYSTEM_NIXOS}/configuration.nix-$(date).bak"
fi
if [[ ! -L ${SYSTEM_NIXOS}/configuration.nix ]]; then
  sudo ln -s "${NIXOS_DIR}/configuration.nix" "${SYSTEM_NIXOS}/configuration.nix"
else
  ok "Symlink exists"
fi
ok "configuration completed"

# ── 4. stow configs ───────────────────────────────────────────────────────────
log "Stowing Configs → ~/.config"
mkdir -p "${HOME}/.config"
cd "${DOTFILES}"
# --adopt would silently clobber; use --no-folding + check for conflicts first
if ! stow --simulate -t "${HOME}/.config" Configs &>/dev/null; then
    die "stow reports conflicts — run 'stow --simulate -t ~/.config Configs' to inspect"
fi
stow --restow -t "${HOME}/.config" Configs
ok "Stow complete"

# ── 5. fonts, wallpapers, icons ───────────────────────────────────────────────
log "Installing fonts"
mkdir -p "${HOME}/.local/share/fonts"
cp -r -- "${DOTFILES}/Configs/Resources/fonts/." "${HOME}/.local/share/fonts/"
fc-cache -f "${HOME}/.local/share/fonts" || true  # best-effort
ok "Fonts installed"

log "Installing wallpapers"
cp -r -- "${DOTFILES}/Configs/Resources/Wallpapers" "${HOME}/"
ok "Wallpapers copied"

log "Installing cursor theme"
mkdir -p "${HOME}/.local/share/icons"
cp -r -- "${DOTFILES}/Configs/Resources/Bibata-Modern-Ice" "${HOME}/.local/share/icons/"
ok "Cursor theme installed"

# ── 7. bluetooth ──────────────────────────────────────────────────────────────
log "Unblocking bluetooth"
sudo rfkill unblock bluetooth
ok "Bluetooth unblocked"

# ── 8. nixos rebuild ──────────────────────────────────────────────────────────
log "Updating flake inputs"
# sudo nix flake update
log "Rebuilding NixOS"
sudo nixos-rebuild switch
ok "NixOS rebuild complete"

# ── 9. launch editor (non-blocking, after rebuild) ────────────────────────────
log "Launching Neovim in Kitty"
kitty -- nvim &
disown

ok "Install complete"
