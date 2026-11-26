#!/usr/bin/env bash

[ $# -eq 0 ] && { echo "Usage: ${0##*/} <file|dir>..."; exit 1; }

device=$(kdeconnect-cli -l --id-only | head -n 1)

if [ -z "$device" ]; then
    notify-send "KDE Connect" "No device found"
    exit 1
fi

files=()
for arg in "$@"; do
    if [ -d "$arg" ]; then
        while IFS= read -r -d '' f; do files+=("$f"); done \
            < <(find "$arg" -type f -print0)
    elif [ -f "$arg" ]; then
        files+=("$arg")
    else
        echo "Skip: $arg (not found)" >&2
    fi
done

total=${#files[@]}
[ "$total" -eq 0 ] && { notify-send "KDE Connect" "No valid files"; exit 1; }

ok=0
for f in "${files[@]}"; do
    kdeconnect-cli --share "$f" -d "$device" && ((ok++))
done

if [ "$total" -eq 1 ]; then
    notify-send "KDE Connect" "Sent: $(basename "${files[0]}")"
else
    notify-send "KDE Connect" "Sent $ok/$total files"
fi
