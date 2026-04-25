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

DOTFILES="${HOME}/NixOS-dotfiles"
NIXOS_DIR="${DOTFILES}/NixOS"
SYSTEM_NIXOS="/etc/nixos"

# ── 1. rename dotfiles dir (idempotent) ────────────────────────────────────────
OLD_DOTFILES="${HOME}/nixos-dotfiles"
if [[ -d "${OLD_DOTFILES}" && ! -d "${DOTFILES}" ]]; then
    log "Renaming dotfiles directory"
    mv -- "${OLD_DOTFILES}" "${DOTFILES}"
    ok "Renamed nixos-dotfiles → NixOS-dotfiles"
elif [[ -d "${OLD_DOTFILES}" && -d "${DOTFILES}" ]]; then
    die "Both ~/nixos-dotfiles and ~/NixOS-dotfiles exist — resolve manually"
fi

[[ -d "${DOTFILES}" ]] || die "Dotfiles directory not found: ${DOTFILES}"

# ── 2. back up and replace NixOS config ───────────────────────────────────────
log "Backing up /etc/nixos/configuration.nix"
if [[ -f "${SYSTEM_NIXOS}/configuration.nix" ]]; then
    sudo cp --backup=numbered \
        "${SYSTEM_NIXOS}/configuration.nix" \
        "${SYSTEM_NIXOS}/configuration.nix.bak"
    ok "Backup written (numbered)"
else
    log "No configuration.nix found — skipping backup"
fi

# ── 3. pull hardware-configuration into dotfiles ──────────────────────────────
HW_SRC="${SYSTEM_NIXOS}/hardware-configuration.nix"
HW_DST="${NIXOS_DIR}/hardware-configuration.nix"

log "Importing hardware-configuration.nix"
[[ -f "${HW_SRC}" ]] || die "hardware-configuration.nix not found at ${HW_SRC}"

# Remove stale copy first, then move the live one
rm -f "${HW_DST}"
sudo cp -- "${HW_SRC}" "${HW_DST}"
sudo chown "$(id -un):$(id -gn)" "${HW_DST}"
ok "hardware-configuration.nix → ${HW_DST}"

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
cp -r -- "${DOTFILES}/Configs/Resources/Wallpapers" "${HOME}/Wallpapers"
ok "Wallpapers copied"

log "Installing cursor theme"
mkdir -p "${HOME}/.local/share/icons"
cp -r -- "${DOTFILES}/Configs/Resources/Bibata-Modern-Ice" "${HOME}/.local/share/icons/"
ok "Cursor theme installed"

# ── 6. lazy.nvim ──────────────────────────────────────────────────────────────
LAZY_DIR="${HOME}/.local/share/nvim/lazy/lazy.nvim"
log "Installing lazy.nvim"
rm -rf -- "${LAZY_DIR}"
git clone \
    --filter=blob:none \
    --branch=stable \
    https://github.com/folke/lazy.nvim.git \
    "${LAZY_DIR}"
ok "lazy.nvim installed"

# ── 7. bluetooth ──────────────────────────────────────────────────────────────
log "Unblocking bluetooth"
sudo rfkill unblock bluetooth
ok "Bluetooth unblocked"

# ── 8. nixos rebuild ──────────────────────────────────────────────────────────
log "Updating flake inputs"
sudo nix flake update "${NIXOS_DIR}"

log "Rebuilding NixOS"
sudo nixos-rebuild switch --flake "${NIXOS_DIR}#NixOS"
ok "NixOS rebuild complete"

# ── 9. launch editor (non-blocking, after rebuild) ────────────────────────────
log "Launching Neovim in Kitty"
kitty -- nvim &
disown

ok "Install complete"

