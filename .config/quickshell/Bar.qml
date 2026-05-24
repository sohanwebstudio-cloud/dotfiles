import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Networking
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    exclusiveZone: Colors.barH
    implicitHeight: Colors.barH
    color: Colors.bgBase

    // ── State ────────────────────────────────────────────────────────────

    property string windowTitle: ""
    property string ppText:    ""
    property string khalText:  ""

    property bool   batNotif20:  false
    property bool   batNotif10:  false

    Connections {
        target: SystemMetrics
        function onBatPctChanged() {
            var p = parseInt(SystemMetrics.batPct)
            if (isNaN(p)) return
            if (SystemMetrics.batStatus === "Charging" || SystemMetrics.batStatus === "Full") {
                bar.batNotif20 = false
                bar.batNotif10 = false
                return
            }
            if (p <= 10 && !bar.batNotif10) {
                bar.batNotif10 = true
                bar.batNotif20 = true
                batNotif10Proc.running = true
            } else if (p <= 20 && !bar.batNotif20) {
                bar.batNotif20 = true
                batNotif20Proc.running = true
            }
        }
    }

    // Pipewire audio (pour scroll/mute interactif)
    property var  sink:     Pipewire.defaultAudioSink
    property var  sinkAudio: sink ? sink.audio : null

    // Power Profiles (UPower)
    property string ppIcon: {
        var p = PowerProfiles.profile
        if (p === PowerProfile.Performance) return "󰓅"
        if (p === PowerProfile.PowerSaver)  return "󰾆"
        return "󰾅"
    }
    property string ppName: {
        var p = PowerProfiles.profile
        if (p === PowerProfile.Performance) return "PERF"
        if (p === PowerProfile.PowerSaver)  return "SAVE"
        return "BAL"
    }

    // Battery icon
    property string batIcon: {
        if (SystemMetrics.batStatus === "Charging" || SystemMetrics.batStatus === "Full") return "󰂄"
        var p = parseInt(SystemMetrics.batPct)
        if (isNaN(p)) return "󱉝"
        if (p > 90) return "󰁹"
        if (p > 70) return "󰂀"
        if (p > 50) return "󰁿"
        if (p > 30) return "󰁼"
        if (p > 10) return "󰁺"
        return "󰂃"
    }

    // I3/Sway window title tracking
    I3IpcListener {
        subscriptions: ["window"]
        onIpcEvent: event => {
            try {
                var d = JSON.parse(event.data)
                var isThis = I3.monitorFor(bar.screen) === I3.focusedMonitor
                if ((d.change === "focus" || d.change === "title") && d.container && isThis)
                    bar.windowTitle = d.container.name || ""
                else if (d.change === "close" && isThis)
                    bar.windowTitle = ""
            } catch(e) {}
        }
    }


    // Khal calendar — refresh every 5 min
    Process {
        id: khalProc
        command: ["/home/sohan/.local/bin/waybar-khal"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try { bar.khalText = JSON.parse(line).text || "" } catch(e) {}
            }
        }
    }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: khalProc.running = true }

    // Processes réutilisables — évite les fuites Qt.createQmlObject
    Process { id: batNotif10Proc; command: ["notify-send", "-u", "critical", "-t", "0", "Batterie critique !", "10% restant — branchez le chargeur maintenant."]; running: false }
    Process { id: batNotif20Proc; command: ["notify-send", "-u", "normal",   "-t", "8000", "Batterie faible", "20% restant."]; running: false }
    Process { id: khalOpenProc;   command: ["kitty", "--class", "qs-popup", "-e", "khal", "interactive"]; running: false }
    Process { id: ppCycleProc;    command: ["/home/sohan/.local/bin/power-profile-cycle"]; running: false }
    Process { id: btOpenProc;     command: ["kitty", "--class", "qs-popup", "-e", "/home/sohan/.local/bin/bluetuith-wal"]; running: false }
    Process { id: netOpenProc;    command: ["kitty", "--class", "qs-popup", "-e", "/home/sohan/.local/bin/nmtui-wal"]; running: false }
    Process { id: powerMenuProc;  command: ["quickshell", "ipc", "call", "shell", "togglePowerMenu"]; running: false }

    // ── Bottom border ────────────────────────────────────────────────────
    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 1
        color: Colors.border
    }

    // ── Scanline CRT overlay ─────────────────────────────────────────────
    Canvas {
        anchors.fill: parent
        opacity: 0.08
        z: 10
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "#000000"
            for (var y = 0; y < height; y += 2)
                ctx.fillRect(0, y, width, 1)
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ── Horloge ancrée AU CENTRE ABSOLU de la bar ────────────────────────
    Text {
        anchors.centerIn: parent
        z: 5
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  hh:mm:ss").toUpperCase()
        color: Colors.text
        font { family: Colors.font; pixelSize: Colors.sz; letterSpacing: 2 }
    }

    // ── LEFT block : workspaces + window title ───────────────────────────
    RowLayout {
        id: leftRow
        anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: Colors.padSm }
        spacing: 0

        // ─ LEFT: workspaces + window title ──────────────────────────────
        Repeater {
            model: I3.workspaces

            delegate: Rectangle {
                required property var modelData
                property bool active: modelData.focused
                property bool urgent: modelData.urgent
                visible: modelData.monitor && modelData.monitor.name === bar.screen.name

                color:         active ? Colors.bgPanel : "transparent"
                border.color:  urgent ? Colors.accent : "transparent"
                border.width:  urgent ? 1 : 0
                width:         visible ? Colors.barH - 6 : 0
                height:        Colors.barH - 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text:  modelData.name
                    color: active ? Colors.gold : urgent ? Colors.accent : Colors.textDim
                    font { family: Colors.font; pixelSize: Colors.sz }
                }

                layer.enabled: true
                layer.effect: Glow {
                    samples: 7; radius: active ? 3 : 0; color: active ? Colors.textBright : "transparent"; transparentBorder: true; spread: 0.1
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: I3.dispatch("workspace " + modelData.name)
                }
            }
        }

        Text {
            text: " › "
            color: Colors.border
            font { family: Colors.font; pixelSize: Colors.sz }
            visible: bar.windowTitle.length > 0
        }
        Text {
            text: bar.windowTitle
            color: Colors.text
            font { family: Colors.font; pixelSize: Colors.szSm }
            elide: Text.ElideRight
            Layout.maximumWidth: 400
        }

    }

    // ── RIGHT block : pills ──────────────────────────────────────────────
    RowLayout {
        id: rightRow
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Colors.padSm }
        spacing: 0

        BarPill {
            text: bar.khalText
            color: Colors.text
            visible: text.length > 0
            onClicked: if (!khalOpenProc.running) khalOpenProc.running = true
        }

        BarPill {
            text: bar.ppIcon + " " + bar.ppName
            color: {
                var p = PowerProfiles.profile
                if (p === PowerProfile.Performance) return Colors.accent
                if (p === PowerProfile.PowerSaver)  return Colors.green
                return Colors.text
            }
            onClicked: if (!ppCycleProc.running) ppCycleProc.running = true
        }

        BarPill {
            text: (SystemMetrics.volMuted ? "MUTE" : "VOL") + " " + SystemMetrics.volPct + "%"
            color: SystemMetrics.volMuted ? Colors.textDim : Colors.text
            onWheel: event => {
                if (bar.sinkAudio) {
                    var d = event.angleDelta.y > 0 ? 0.03 : -0.03
                    bar.sinkAudio.volume = Math.max(0, Math.min(1.5, bar.sinkAudio.volume + d))
                }
            }
            onClicked: { if (bar.sinkAudio) bar.sinkAudio.muted = !bar.sinkAudio.muted }
        }

        BarPill {
            property var adapter: Bluetooth.defaultAdapter
            property bool btConnected: {
                if (!adapter?.enabled) return false
                var devs = adapter.devices.values
                for (var d of devs) if (d.connected) return true
                return false
            }
            text: btConnected ? "󰂱" : (adapter?.enabled ? "󰂯" : "󰂲")
            color: btConnected ? Colors.textBright : Colors.textDim
            onClicked: if (!btOpenProc.running) btOpenProc.running = true
        }

        BarPill {
            property bool online: SystemMetrics.netName !== "offline"
            text: (online ? "󰤨 " : "󰤭 ") + SystemMetrics.netName
            color: online ? Colors.text : Colors.textDim
            Layout.maximumWidth: 130
            onClicked: if (!netOpenProc.running) netOpenProc.running = true
        }

        BarPill {
            text: "CPU " + SystemMetrics.cpuPct + "%"
            color: SystemMetrics.cpuPct > 80 ? Colors.accent : SystemMetrics.cpuPct > 50 ? Colors.textBright : Colors.text
        }

        BarPill {
            text: "GPU " + SystemMetrics.gpuPct + "%"
            color: SystemMetrics.gpuPct > 70 ? Colors.accent : SystemMetrics.gpuPct > 30 ? Colors.textBright : Colors.text
        }

        BarPill {
            text: "MEM " + SystemMetrics.memStr
            color: SystemMetrics.memPct > 75 ? Colors.accent : SystemMetrics.memPct > 50 ? Colors.textBright : Colors.text
        }

        BarPill {
            text: bar.batIcon + " " + SystemMetrics.batPct + "%"
            color: {
                var p = parseInt(SystemMetrics.batPct)
                if (SystemMetrics.batStatus === "Charging") return Colors.green
                if (p < 20) return Colors.red
                return Colors.text
            }
        }

        Rectangle {
            width: 24; height: Colors.barH - 4
            color: "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: Colors.red
                font { family: Colors.font; pixelSize: Colors.sz }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (!powerMenuProc.running) powerMenuProc.running = true
            }
        }
    }
}
