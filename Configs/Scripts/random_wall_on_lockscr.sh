#!/usr/bin/env bash

WALL_DIR="$HOME/Wallpapers"
THEME_DIR="$HOME/.config/hypr/hyprlock_themes"

IMG=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)
THEME=$(find "$THEME_DIR" -type f | shuf -n 1)

cp "$IMG" ~/.cache/hyprlock_wall.png
hyprlock -c "$THEME"
