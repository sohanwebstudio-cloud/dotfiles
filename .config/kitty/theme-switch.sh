#!/bin/bash
# Usage: theme-switch.sh dark|light
MODE="${1:-dark}"
KITTY_CONFIG="$HOME/.config/kitty"
YAZI_CONFIG="$HOME/.config/yazi"

cp "$KITTY_CONFIG/$MODE.conf" "$KITTY_CONFIG/current-theme.conf"
cp "$YAZI_CONFIG/theme-$MODE.toml" "$YAZI_CONFIG/theme.toml"
pgrep kitty | xargs -r kill -SIGUSR1 2>/dev/null
