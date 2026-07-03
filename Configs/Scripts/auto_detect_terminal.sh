#!/usr/bin/env bash

TERMINALS=(
  foot
  kitty
  alacritty
  ghostty
  wezterm
  konsole
  gnome-terminal
  xfce4-terminal
  lxterminal
  mate-terminal
  tilix
  urxvt
  rxvt
  st
  xterm
)

for term in "${TERMINALS[@]}"; do
  if command -v "$term" &>/dev/null; then
    "$term" &
    exit 0
  fi
done

pw-play /run/current-system/sw/share/sounds/freedesktop/stereo/dialog-error.oga
notify-send "No Terminal Found" "Please install a terminal emulator"
