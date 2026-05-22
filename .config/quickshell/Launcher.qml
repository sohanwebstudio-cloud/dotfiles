import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "."

PanelWindow {
    id: launcher

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: Qt.rgba(0.027, 0.02, 0, 0.92)
    focusable: true

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: launcher.visible = false
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }

    property string query: ""
    property int selectedIdx: 0

    // ── Background click ─────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: launcher.visible = false
    }

    // ── Panel ────────────────────────────────────────────────────────────
    Rectangle {
        width: 640
        anchors.centerIn: parent
        height: Math.min(panelCol.implicitHeight + Colors.pad * 2, launcher.height - 80)
        color: Colors.bgPanel
        border { color: Colors.borderBright; width: 1 }
        radius: 2


        Column {
            id: panelCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.pad }
            spacing: Colors.padSm

            // Search bar
            Rectangle {
                width: parent.width
                height: 38
                color: Colors.bgBase
                border { color: Colors.borderBright; width: 1 }

                RowLayout {
                    anchors { fill: parent; leftMargin: Colors.pad; rightMargin: Colors.pad }

                    Text {
                        text: "›"
                        color: Colors.accent
                        font { family: Colors.font; pixelSize: Colors.szLg; weight: Font.Bold }
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        color: Colors.textBright
                        font { family: Colors.font; pixelSize: Colors.sz }
                        selectionColor: Colors.accent
                        cursorVisible: true
                        focus: true

                        onTextChanged: {
                            launcher.query = text.toLowerCase()
                            launcher.selectedIdx = 0
                        }

                        Keys.onUpPressed:     launcher.selectedIdx = Math.max(0, launcher.selectedIdx - 1)
                        Keys.onDownPressed:   launcher.selectedIdx = Math.min(appRepeater.count - 1, launcher.selectedIdx + 1)
                        Keys.onReturnPressed: launchSelected()
                        Keys.onEscapePressed: launcher.visible = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Colors.border }

            // App list
            Flickable {
                id: flick
                width: parent.width
                height: Math.min(appCol.implicitHeight, 440)
                contentHeight: appCol.implicitHeight
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { color: Colors.border; radius: 2; implicitWidth: 4 }
                }

                Column {
                    id: appCol
                    width: flick.width

                    Repeater {
                        id: appRepeater
                        model: DesktopEntries.applications

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            property bool matches: !modelData.noDisplay && (
                                launcher.query === "" ||
                                (modelData.name || "").toLowerCase().includes(launcher.query) ||
                                (modelData.genericName || "").toLowerCase().includes(launcher.query)
                            )
                            property bool isSel: visible && index === launcher.selectedIdx

                            visible: matches
                            width: appCol.width
                            height: matches ? 36 : 0

                            color: isSel ? Qt.rgba(0.18, 0.10, 0, 1) : (ma.containsMouse ? Colors.bgBase : "transparent")
                            border { color: isSel ? Colors.borderBright : "transparent"; width: 1 }

                            RowLayout {
                                anchors { fill: parent; leftMargin: Colors.pad; rightMargin: Colors.pad }
                                spacing: Colors.padSm

                                Text {
                                    text: isSel ? "▶" : " "
                                    color: Colors.accent
                                    font { family: Colors.font; pixelSize: Colors.sz }
                                }
                                Text {
                                    text: modelData.name || ""
                                    color: isSel ? Colors.gold : Colors.text
                                    font { family: Colors.font; pixelSize: Colors.sz }
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.genericName || ""
                                    color: Colors.textDim
                                    font { family: Colors.font; pixelSize: Colors.szSm }
                                    visible: text.length > 0
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:  doLaunch(modelData)
                                onEntered:  launcher.selectedIdx = index
                            }
                        }
                    }
                }
            }

            Text {
                text: "  ENTER lancer · ESC fermer · ↑↓ naviguer"
                color: Colors.textDim
                font { family: Colors.font; pixelSize: Colors.szSm - 1 }
                bottomPadding: Colors.padSm
            }
        }
    }

    // ── Lancement ────────────────────────────────────────────────────────
    function launchSelected() {
        // Trouve le premier item visible avec index === selectedIdx
        for (var i = 0; i < appRepeater.count; i++) {
            var item = appRepeater.itemAt(i)
            if (item && item.visible && item.index === launcher.selectedIdx) {
                doLaunch(item.modelData)
                return
            }
        }
    }

    function doLaunch(entry) {
        if (!entry || !entry.execString) return
        var p = Qt.createQmlObject(
            'import Quickshell.Io; Process { running: false }',
            launcher, "launchProc"
        )
        p.command = ["swaymsg", "exec", "--", entry.execString]
        p.running = true
        launcher.visible = false
    }
}
