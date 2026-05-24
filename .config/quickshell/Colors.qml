pragma Singleton
import QtQuick

// Amber Phosphor CRT palette
QtObject {
    readonly property color bgBase:        "#070500"
    readonly property color bgPanel:       "#160C00"
    readonly property color bgOverlay:     "#0D0700"
    readonly property color border:        "#3A2300"
    readonly property color borderBright:  "#7A4A00"
    readonly property color textDim:       "#7A5810"
    readonly property color text:          "#C87A0A"
    readonly property color textBright:    "#F0A000"
    readonly property color accent:        "#FF7800"
    readonly property color gold:          "#FFD060"
    readonly property color green:         "#6B9000"
    readonly property color red:           "#C03000"

    readonly property string font:         "VT323"
    readonly property int   barH:          41
    readonly property int   sz:            23
    readonly property int   szSm:          20
    readonly property int   szLg:          29
    readonly property int   pad:           12
    readonly property int   padSm:         7
}
