import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."

// Power menu — fullscreen overlay with retro terminal style popup
// Toggle: quickshell ipc call shell togglePowerMenu
PanelWindow {
    id: powerMenu

    property var targetScreen: null
    screen: targetScreen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: Qt.rgba(0, 0, 0, 0.55)
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Process { id: pmProc; running: false }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: powerMenu.visible = false
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: powerMenu.visible = false
    }

    // Center panel
    Rectangle {
        anchors.centerIn: parent
        width: 230
        height: menuCol.implicitHeight + Colors.pad * 2
        color: Colors.bgPanel
        border { color: Colors.borderBright; width: 1 }
        radius: 2

        Column {
            id: menuCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.pad }
            spacing: Colors.padSm

            Text {
                width: parent.width
                text: "─── POWER ───"
                color: Colors.textDim
                font { family: Colors.font; pixelSize: Colors.szSm }
                horizontalAlignment: Text.AlignHCenter
                bottomPadding: Colors.padSm
            }

            Repeater {
                model: [
                    { icon: "⏻", label: "ÉTEINDRE",   cmd: ["systemctl", "poweroff"] },
                    { icon: "↺",  label: "REDÉMARRER", cmd: ["systemctl", "reboot"]    },
                    { icon: "⏾", label: "SUSPENDRE",  cmd: ["systemctl", "suspend"]   },
                    { icon: "⏏",  label: "DÉCONNEXION",cmd: ["swaymsg",   "exit"]       }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: menuCol.width
                    height: 38
                    color: ma.containsMouse ? Colors.bgBase : "transparent"
                    border { color: ma.containsMouse ? Colors.borderBright : "transparent"; width: 1 }
                    radius: 1

                    RowLayout {
                        anchors { fill: parent; leftMargin: Colors.pad * 2; rightMargin: Colors.pad }
                        spacing: Colors.pad

                        Text {
                            text: modelData.icon
                            color: Colors.accent
                            font { family: Colors.font; pixelSize: Colors.szLg }
                        }
                        Text {
                            text: modelData.label
                            color: ma.containsMouse ? Colors.gold : Colors.text
                            font { family: Colors.font; pixelSize: Colors.sz }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            powerMenu.visible = false
                            pmProc.command = modelData.cmd
                            pmProc.running = true
                        }
                    }
                }
            }

            // Footer
            Text {
                width: parent.width
                text: "ESC pour annuler"
                color: Colors.textDim
                font { family: Colors.font; pixelSize: Colors.szSm - 1 }
                horizontalAlignment: Text.AlignHCenter
                topPadding: Colors.padSm
                bottomPadding: Colors.padSm
            }
        }
    }
}
