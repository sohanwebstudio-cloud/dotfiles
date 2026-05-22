import Quickshell
import Quickshell.Io
import Quickshell.I3
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
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
    property int    cpuPct:      0
    property int    memPct:      0
    property string memStr:      "0/64G"
    property string batPct:      "?"
    property string batStatus:   "?"
    property string netName:     "?"
    property string ppText:      ""
    property string khalText:    ""
    property int    volPct:      0
    property bool   volMuted:    false
    property int    gpuPct:      0
    property int    gpuVram:     0
    property int    gpuVramTotal: 4096

    property bool   batNotif20:  false
    property bool   batNotif10:  false

    onBatPctChanged: {
        var p = parseInt(batPct)
        if (isNaN(p)) return
        if (batStatus === "Charging" || batStatus === "Full") {
            batNotif20 = false
            batNotif10 = false
            return
        }
        if (p <= 10 && !batNotif10) {
            batNotif10 = true
            batNotif20 = true
            Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["notify-send", "-u", "critical", "-t", "0", "Batterie critique !", "10% restant — branchez le chargeur maintenant."]; running: true }',
                bar, "batNotif10"
            )
        } else if (p <= 20 && !batNotif20) {
            batNotif20 = true
            Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["notify-send", "-u", "normal", "-t", "8000", "Batterie faible", "20% restant."]; running: true }',
                bar, "batNotif20"
            )
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

    // Battery icon (from sysmon.sh data)
    property string batIcon: {
        if (batStatus === "Charging" || batStatus === "Full") return "󰂄"
        var p = parseInt(batPct)
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
                if ((d.change === "focus" || d.change === "title") && d.container)
                    bar.windowTitle = d.container.name || ""
                else if (d.change === "close")
                    bar.windowTitle = ""
            } catch(e) {}
        }
    }

    // System metrics (cpu, mem, net, bat percentage)
    Process {
        command: ["/home/sohan/.config/quickshell/scripts/sysmon.sh"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    var d = JSON.parse(line)
                    bar.cpuPct  = d.cpu  || 0
                    bar.memPct  = d.mem  || 0
                    bar.memStr  = (d.mu || "0") + "/" + (d.mt || "64") + "G"
                    bar.batPct  = d.bat  || "?"
                    bar.batStatus = d.bs || "?"
                    bar.netName = d.net  || "offline"
                    bar.volPct      = d.vol  || 0
                    bar.volMuted    = d.vm   || false
                    bar.gpuPct      = d.gpu  || 0
                    bar.gpuVram     = d.gv   || 0
                    bar.gpuVramTotal = d.gvt || 4096
                } catch(e) {}
            }
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

    // ── Main layout ──────────────────────────────────────────────────────
    // ── Clock — vraiment centré dans la barre ────────────────────────────
    SystemClock { id: clock; precision: SystemClock.Seconds }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  hh:mm:ss").toUpperCase()
        color: Colors.text
        font { family: "VT323"; pixelSize: 22; letterSpacing: 2 }
    }

    // ── Left + Right en RowLayout ────────────────────────────────────────
    RowLayout {
        anchors { fill: parent; leftMargin: Colors.padSm; rightMargin: Colors.padSm }
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
                    id: wsText
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

        // separator + window title
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
            Layout.maximumWidth: 600
        }

        Item { Layout.fillWidth: true }

        // ─ RIGHT: widgets ────────────────────────────────────────────────

        // Khal
        BarPill {
            text: bar.khalText
            color: Colors.text
            visible: text.length > 0
            onClicked: Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["kitty", "--class", "qs-popup", "-e", "khal", "interactive"]; running: true }',
                bar, "khalOpen"
            )
        }

        // Power Profile (click to cycle)
        BarPill {
            text: bar.ppIcon + " " + bar.ppName
            color: {
                var p = PowerProfiles.profile
                if (p === PowerProfile.Performance) return Colors.accent
                if (p === PowerProfile.PowerSaver)  return Colors.green
                return Colors.text
            }
            onClicked: {
                var p = Qt.createQmlObject(
                    'import Quickshell.Io; Process { running: false }',
                    bar, "ppCycle"
                )
                p.command = ["/home/sohan/.local/bin/power-profile-cycle"]
                p.running = true
            }
        }


        // Volume (scroll to adjust, click to mute)
        BarPill {
            text: (bar.volMuted ? "MUTE" : "VOL") + " " + bar.volPct + "%"
            color: bar.volMuted ? Colors.textDim : Colors.text
            onWheel: event => {
                if (bar.sinkAudio) {
                    var d = event.angleDelta.y > 0 ? 0.03 : -0.03
                    bar.sinkAudio.volume = Math.max(0, Math.min(1.5, bar.sinkAudio.volume + d))
                }
            }
            onClicked: { if (bar.sinkAudio) bar.sinkAudio.muted = !bar.sinkAudio.muted }
        }

        // Bluetooth
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
            onClicked: Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["kitty", "--class", "qs-popup", "-e", "/home/sohan/.local/bin/bluetuith-wal"]; running: true }',
                bar, "btOpen"
            )
        }

        // Network
        BarPill {
            property bool online: bar.netName !== "offline"
            text: (online ? "󰤨 " : "󰤭 ") + bar.netName
            color: online ? Colors.text : Colors.textDim
            Layout.maximumWidth: 130
            onClicked: Qt.createQmlObject(
                'import Quickshell.Io; Process { command: ["kitty", "--class", "qs-popup", "-e", "/home/sohan/.local/bin/nmtui-wal"]; running: true }',
                bar, "netOpen"
            )
        }

        // CPU
        BarPill {
            text: "CPU " + bar.cpuPct + "%"
            color: bar.cpuPct > 80 ? Colors.accent : bar.cpuPct > 50 ? Colors.textBright : Colors.text
        }

        // GPU
        BarPill {
            text: "GPU " + bar.gpuPct + "%"
            color: bar.gpuPct > 70 ? Colors.accent : bar.gpuPct > 30 ? Colors.textBright : Colors.text
        }

        // Memory
        BarPill {
            text: "MEM " + bar.memStr
            color: bar.memPct > 75 ? Colors.accent : bar.memPct > 50 ? Colors.textBright : Colors.text
        }

        // Battery
        BarPill {
            text: bar.batIcon + " " + bar.batPct + "%"
            color: {
                var p = parseInt(bar.batPct)
                if (bar.batStatus === "Charging") return Colors.green
                if (p < 20) return Colors.red
                return Colors.text
            }
        }

        // System Tray
        Repeater {
            model: SystemTray.items
            delegate: Item {
                required property var modelData
                width: 20; height: Colors.barH
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.centerIn: parent
                    source: modelData.icon
                    width: 14; height: 14
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => modelData.display(bar, mapToItem(null, 0, 0).x, mapToItem(null, 0, 0).y)
                }
            }
        }

        // Power button
        Rectangle {
            width: 24; height: Colors.barH - 4
            color: "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: Colors.red
                font { family: Colors.font; pixelSize: Colors.szLg }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var p = Qt.createQmlObject(
                        'import Quickshell.Io; Process { command: ["quickshell","ipc","call","shell","togglePowerMenu"]; running: true }',
                        bar, "powerBtn"
                    )
                }
            }
        }
    }
}
