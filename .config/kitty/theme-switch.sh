#!/bin/bash
KITTY_CONFIG="$HOME/.config/kitty"
YAZI_CONFIG="$HOME/.config/yazi"
SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ "$SCHEME" == "'prefer-dark'" ]]; then
    cp "$KITTY_CONFIG/dark.conf"       "$KITTY_CONFIG/current-theme.conf"
    cp "$YAZI_CONFIG/theme-dark.toml"  "$YAZI_CONFIG/theme.toml"
else
    cp "$KITTY_CONFIG/light.conf"       "$KITTY_CONFIG/current-theme.conf"
    cp "$YAZI_CONFIG/theme-light.toml"  "$YAZI_CONFIG/theme.toml"
fi

pgrep kitty | xargs -r kill -SIGUSR1 2>/dev/null
