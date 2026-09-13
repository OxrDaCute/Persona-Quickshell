#!/usr/bin/env bash
# Install (or update) Persona blackout on KDE Plasma: the KWin script that
# watches for maximized/fullscreen windows, and the bridge service that relays
# that to the shell. Safe to re-run.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
shell_path=$(dirname "$here")

echo "Installing bridge -> ~/.local/bin/persona-blackout-bridge"
install -Dm755 "$here/persona-blackout-bridge" "$HOME/.local/bin/persona-blackout-bridge"

echo "Installing service -> ~/.config/systemd/user/persona-blackout-bridge.service"
install -Dm644 "$here/persona-blackout-bridge.service" \
    "$HOME/.config/systemd/user/persona-blackout-bridge.service"
# The service defaults to ~/Persona-Quickshell; point it at wherever this repo lives.
sed -i "s|^Environment=PERSONA_SHELL_PATH=.*|Environment=PERSONA_SHELL_PATH=$shell_path|" \
    "$HOME/.config/systemd/user/persona-blackout-bridge.service"

echo "Installing KWin script -> ~/.local/share/kwin/scripts/personablackout"
rm -rf "$HOME/.local/share/kwin/scripts/personablackout"
mkdir -p "$HOME/.local/share/kwin/scripts"
cp -r "$here/kwin/personablackout" "$HOME/.local/share/kwin/scripts/"

echo "Enabling bridge service"
systemctl --user daemon-reload
systemctl --user enable persona-blackout-bridge.service
systemctl --user restart persona-blackout-bridge.service

echo "Enabling KWin script"
kwriteconfig6 --file kwinrc --group Plugins --key personablackoutEnabled true
# Unload first so reconfigure (re)starts it: that picks up edits to main.js, and
# the fresh script reports the current state to the just-restarted bridge.
gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.unloadScript personablackout >/dev/null
gdbus call --session --dest org.kde.KWin --object-path /KWin \
    --method org.kde.KWin.reconfigure >/dev/null

echo "Done. Maximize a window and the Persona desktop should go black."
