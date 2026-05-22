import QtQuick
import QtQuick.Layouts
import "."

// Reusable bar widget pill — wraps a text label with hover highlight and click/wheel signals
Item {
    id: pill

    property string text:  ""
    property color  color: Colors.text
    property alias  font:  label.font

    signal clicked()
    signal wheel(var event)

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: label.implicitWidth + Colors.pad * 2
    implicitHeight: Colors.barH

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Colors.bgPanel : "transparent"
        border.color: ma.containsMouse ? Colors.border : "transparent"
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text:  pill.text
            color: pill.color
            font { family: Colors.font; pixelSize: Colors.szSm }
            elide: Text.ElideRight
            width: Math.min(implicitWidth, pill.implicitWidth - Colors.pad * 2)
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: pill.clicked()
        onWheel: event => pill.wheel(event)
    }
}
