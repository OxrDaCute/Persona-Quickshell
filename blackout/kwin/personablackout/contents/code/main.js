// Persona Blackout — tells the Persona Quickshell shell to blank itself
// whenever the active window is maximized or fullscreen, i.e. whenever the
// desktop underneath genuinely isn't visible.
//
// KWin scripts cannot execute processes, only make D-Bus calls, so this talks
// to a small bridge service (persona-blackout-bridge) that owns
// org.persona.Blackout and forwards the state to `qs ipc call`.

var DBUS_SERVICE = "org.persona.Blackout";
var DBUS_PATH = "/Blackout";
var DBUS_IFACE = "org.persona.Blackout";

var lastState = null;
var attached = {};

// A window counts as covering the desktop when it is fullscreen, or when its
// frame fills the screen's maximize area. Comparing geometry rather than
// reading a `maximized` property keeps this working across KWin versions,
// which have moved that property around.
function coversDesktop(w) {
    if (!w) {
        return false;
    }
    if (w.minimized) {
        return false;
    }
    // Ignore the shell's own surfaces and other non-application windows.
    if (w.desktopWindow || w.dock || w.onScreenDisplay || w.notification
        || w.criticalNotification || w.splash || w.toolbar || w.utility
        || w.popupWindow || w.tooltip) {
        return false;
    }
    if (w.fullScreen) {
        return true;
    }

    var area = workspace.clientArea(KWin.MaximizeArea, w);
    var g = w.frameGeometry;
    if (!area || !g) {
        return false;
    }

    var slack = 4; // shadows and rounding
    return g.width >= area.width - slack
        && g.height >= area.height - slack
        && g.x <= area.x + slack
        && g.y <= area.y + slack;
}

function update() {
    var state = coversDesktop(workspace.activeWindow);
    if (state === lastState) {
        return;
    }
    lastState = state;
    print("persona-blackout: covered =", state);
    callDBus(DBUS_SERVICE, DBUS_PATH, DBUS_IFACE, "SetCovered", state);
}

// Re-evaluate whenever this window's geometry or state could change the answer.
function attach(w) {
    if (!w) {
        return;
    }
    var key = String(w.internalId);
    if (attached[key]) {
        return;
    }
    attached[key] = true;

    if (w.frameGeometryChanged) {
        w.frameGeometryChanged.connect(update);
    }
    if (w.fullScreenChanged) {
        w.fullScreenChanged.connect(update);
    }
    if (w.minimizedChanged) {
        w.minimizedChanged.connect(update);
    }
    if (w.maximizedChanged) {
        w.maximizedChanged.connect(update);
    }
}

workspace.windowActivated.connect(function (w) {
    attach(w);
    update();
});

workspace.windowAdded.connect(function (w) {
    attach(w);
    update();
});

workspace.windowRemoved.connect(function (w) {
    if (w) {
        delete attached[String(w.internalId)];
    }
    update();
});

// Switching desktop or screen changes which window is active/visible.
if (workspace.currentDesktopChanged) {
    workspace.currentDesktopChanged.connect(update);
}

var existing = workspace.windowList ? workspace.windowList() : [];
for (var i = 0; i < existing.length; i++) {
    attach(existing[i]);
}

update();
