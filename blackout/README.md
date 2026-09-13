# Blackout (KDE Plasma)

Blanks the Persona desktop and pauses its animations whenever the active window
is maximized or fullscreen, so the shell stops using CPU while you can't see it.

```
KWin script  →  D-Bus (org.persona.Blackout)  →  bridge  →  qs ipc call  →  Data/Blackout.qml
```

KWin scripts can't run programs and Quickshell's IPC isn't D-Bus, so a small
bridge service sits in between. The shell also asks the bridge for the current
state when it launches.

## Install

```bash
./blackout/install.sh
```

Needs KDE Plasma 6, Python 3 with PyGObject, and `busctl` (systemd).

## Files

| File | Installed to |
|---|---|
| `persona-blackout-bridge` | `~/.local/bin/` |
| `persona-blackout-bridge.service` | `~/.config/systemd/user/` |
| `kwin/personablackout/` | `~/.local/share/kwin/scripts/` |

After editing any of these, run `install.sh` again to apply the change.

## Use

```bash
journalctl --user -u persona-blackout-bridge -f          # watch it live
qs -p ~/Persona-Quickshell ipc call blackout status      # current state
qs -p ~/Persona-Quickshell ipc call blackout toggle      # force on/off
```

Set `idleSeconds` in `Data/Blackout.qml` to also blank after a period without input.

## Uninstall

```bash
systemctl --user disable --now persona-blackout-bridge
kwriteconfig6 --file kwinrc --group Plugins --key personablackoutEnabled false
rm -rf ~/.local/bin/persona-blackout-bridge \
       ~/.config/systemd/user/persona-blackout-bridge.service \
       ~/.local/share/kwin/scripts/personablackout
```
