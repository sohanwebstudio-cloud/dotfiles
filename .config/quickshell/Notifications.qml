import Quickshell
import Quickshell.Services.Notifications
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import "."

// Notification daemon — replaces mako
// Shows toast popups in the top-right corner of the primary screen
Scope {
    id: notifScope

    property var targetScreen: null

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true

        onNotification: n => {
            n.tracked = true
            popups.add(n)
        }
    }

    // Toast popup panel anchored to top-right
    PanelWindow {
        id: toastPanel

        screen: notifScope.targetScreen
        anchors { top: true; right: true }
        exclusiveZone: 0
        implicitWidth: 340
        implicitHeight: toastColumn.implicitHeight + Colors.pad * 2
        visible: toastColumn.count > 0 && notifScope.targetScreen !== null
        color: "transparent"

        Column {
            id: toastColumn
            anchors { top: parent.top; right: parent.right; margins: Colors.pad }
            spacing: Colors.padSm

            property int count: 0

            function add(n) {
                toastComp.createObject(toastColumn, { notification: n })
                count++
            }
        }

        Component {
            id: toastComp

            Rectangle {
                id: toast
                required property var notification

                width: 320
                height: toastContent.implicitHeight + Colors.pad * 2
                color: Colors.bgPanel
                border { color: urgentBorder; width: 1 }
                radius: 2

                property color urgentBorder: {
                    var u = notification?.urgency
                    if (u === 2) return Colors.red
                    if (u === 1) return Colors.borderBright
                    return Colors.border
                }

                // Glow on urgent
                layer.enabled: notification?.urgency === 2
                layer.effect: Glow {
                    samples: 9; radius: 6; color: Colors.red; transparentBorder: true
                }

                // Auto-dismiss
                Timer {
                    interval: notification?.expireTimeout > 0 ? notification.expireTimeout : 6000
                    running: true
                    onTriggered: dismiss()
                }

                function dismiss() {
                    toastColumn.count--
                    toast.destroy()
                }

                Column {
                    id: toastContent
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.pad }
                    spacing: 3

                    RowLayout {
                        width: parent.width

                        Text {
                            text: notification?.appName?.toUpperCase() ?? ""
                            color: Colors.textDim
                            font { family: Colors.font; pixelSize: Colors.szSm; weight: Font.Bold }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "×"
                            color: Colors.textDim
                            font { family: Colors.font; pixelSize: Colors.szLg }
                            MouseArea { anchors.fill: parent; onClicked: toast.dismiss() }
                        }
                    }

                    Text {
                        width: parent.width
                        text: notification?.summary ?? ""
                        color: Colors.textBright
                        font { family: Colors.font; pixelSize: Colors.sz; weight: Font.Bold }
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: notification?.body ?? ""
                        color: Colors.text
                        font { family: Colors.font; pixelSize: Colors.szSm }
                        visible: text.length > 0
                        wrapMode: Text.WordWrap
                    }
                }

                // Click to dismiss
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: toast.dismiss()
                }

                // Slide-in animation
                NumberAnimation on opacity { from: 0; to: 1; duration: 150 }
                NumberAnimation on x      { from: 50; to: 0; duration: 150; easing.type: Easing.OutQuart }
            }
        }
    }

    // Internal list — not a QML model, just reference tracking
    QtObject {
        id: popups
        function add(n) { toastColumn.add(n) }
    }
}
