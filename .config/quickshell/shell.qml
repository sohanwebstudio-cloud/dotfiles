import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    id: root

    // Résout eDP-1 parmi les screens disponibles, fallback sur le premier
    // Quickshell.screens est une QQmlListProperty indexable, notify: screensChanged
    property var primaryScreen: {
        var i = 0
        while (true) {
            var s = Quickshell.screens[i]
            if (!s) break
            if (s.name === "eDP-1") return s
            i++
        }
        return Quickshell.screens[0] ?? null
    }

    // IPC: called from Sway keybinds via `quickshell ipc call shell <fn>`
    IpcHandler {
        target: "shell"
        function toggleLauncher(): void { launcher.visible = !launcher.visible }
        function togglePowerMenu(): void  { powerMenu.visible  = !powerMenu.visible  }
    }

    Bar {
        screen: root.primaryScreen
        visible: root.primaryScreen !== null
    }

    Notifications { targetScreen: root.primaryScreen }

    // Global overlays (hidden by default)
    Launcher  { id: launcher;  visible: false; targetScreen: root.primaryScreen }
    PowerMenu { id: powerMenu; visible: false; targetScreen: root.primaryScreen }
}
