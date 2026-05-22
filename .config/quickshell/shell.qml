import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    id: root

    // IPC: called from Sway keybinds via `quickshell ipc call shell <fn>`
    IpcHandler {
        target: "shell"
        function toggleLauncher(): void { launcher.visible = !launcher.visible }
        function togglePowerMenu(): void  { powerMenu.visible  = !powerMenu.visible  }
    }

    // One bar per screen
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Notifications {}

    // Global overlays (hidden by default)
    Launcher  { id: launcher;  visible: false }
    PowerMenu { id: powerMenu; visible: false }
}
