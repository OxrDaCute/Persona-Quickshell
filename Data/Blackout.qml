pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Central "the desktop isn't being looked at" switch.
//
// When this goes true every layer that animates is expected to stop animating
// outright, not merely hide itself: QML animations are driven by Qt's animation
// driver rather than by Wayland frame callbacks, so a covered-up surface keeps
// burning CPU unless its animations are actually stopped.
//
// Two triggers:
//   * idle      - automatic, via ext_idle_notifier_v1 (works on KWin)
//   * forced    - manual, via `qs ipc call blackout enable|disable|toggle`
//
// There is deliberately no "a window is focused" trigger: this compositor
// advertises neither zwlr_foreign_toplevel_manager_v1 nor
// org_kde_plasma_window_management, and org.kde.KWin's D-Bus API has no
// active-window getter, so nothing here can see the window stack. Drive
// `forced` from outside if you want that behaviour.
Singleton {
    id: root

    // Also blank after this many seconds without input. 0 disables it; the
    // window-covered trigger below is the primary one. Set to e.g. 300 if you
    // want the shell to stop animating when you walk away, too.
    property int idleSeconds: 0

    // Manual override, toggled over IPC.
    property bool forced: false

    // Set by the personablackout KWin script (via the D-Bus bridge) whenever the
    // active window is maximized or fullscreen, i.e. the desktop is covered.
    property bool windowCovered: false

    readonly property bool active: root.forced || root.windowCovered
        || (root.idleSeconds > 0 && idleMonitor.isIdle)

    IdleMonitor {
        id: idleMonitor
        enabled: root.idleSeconds > 0
        timeout: root.idleSeconds
        respectInhibitors: true
    }

    IpcHandler {
        target: "blackout"

        function enable(): void {
            root.forced = true;
        }
        function disable(): void {
            root.forced = false;
        }
        function toggle(): void {
            root.forced = !root.forced;
        }
        function setCovered(covered: bool): void {
            root.windowCovered = covered;
        }
        function status(): string {
            return (root.active ? "on" : "off") + " (forced=" + root.forced + " covered=" + root.windowCovered + " idle=" + idleMonitor.isIdle + ")";
        }
    }
}
