#!/bin/bash
# Watches GNOME color-scheme and calls theme-switch.sh on change
SWITCH="$HOME/.config/kitty/theme-switch.sh"

"$SWITCH"

gsettings monitor org.gnome.desktop.interface color-scheme | while IFS= read -r _; do
    "$SWITCH"
done
