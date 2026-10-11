import QtQuick
import QtQuick.Controls
import "../"

Button {
    id: btn
    // "solid" | "ghost" | "danger" | "success" | "subtle"
    property string variant: "solid"
    property string iconText: ""
    property int    iconSize: 13
    property color  solidColor: Theme.accent

    hoverEnabled: true

    readonly property color _fg: {
        if (variant === "solid")   return Theme.crust
        if (variant === "danger")  return "#ff6e6e"
        if (variant === "success") return "#5af78e"
        if (variant === "subtle")  return btn.hovered ? Theme.text : Theme.subtext0
        return Theme.text
    }
    readonly property color _bg: {
        if (variant === "solid")   return btn.hovered ? Theme.accentHover : solidColor
        if (variant === "danger")  return btn.hovered ? Qt.rgba(1.0, 0.25, 0.25, 0.22) : Qt.rgba(1.0, 0.25, 0.25, 0.12)
        if (variant === "success") return btn.hovered ? Qt.rgba(0.25, 1.0, 0.5, 0.22) : Qt.rgba(0.25, 1.0, 0.5, 0.12)
        if (variant === "subtle")  return btn.hovered ? Theme.surface2 : "transparent"
        return btn.hovered ? Theme.surface2 : Theme.surface1
    }
    readonly property color _border: {
        if (variant === "solid")   return btn.hovered ? Qt.rgba(255, 255, 255, 0.5) : "transparent"
        if (variant === "danger")  return btn.hovered ? Qt.rgba(1.0, 0.25, 0.25, 0.55) : Qt.rgba(1.0, 0.25, 0.25, 0.25)
        if (variant === "success") return btn.hovered ? Qt.rgba(0.25, 1.0, 0.5, 0.55) : Qt.rgba(0.25, 1.0, 0.5, 0.25)
        if (variant === "subtle")  return "transparent"
        return btn.hovered ? Theme.accent : Theme.border
    }

    implicitHeight: 34
    implicitWidth: Math.max(84, contentRow.implicitWidth + 28)
    padding: 6
    leftPadding: 14
    rightPadding: 14

    // ── Button Animations: Hover Lift & Spring Bounce ──────────
    transform: Translate {
        y: btn.down ? 1 : (btn.hovered ? -2 : 0)
        Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
    }

    scale: btn.down ? 0.93 : (btn.hovered ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

    contentItem: Item {
        anchors.fill: parent
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                visible: btn.iconText.length > 0
                text: btn.iconText
                font.family: Theme.fontIcon
                font.pixelSize: btn.iconSize
                anchors.verticalCenter: parent.verticalCenter
                color: btn._fg

                scale: btn.hovered ? 1.18 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
            }

            Text {
                visible: btn.text.length > 0
                text: btn.text
                font.family: Theme.fontUI
                font.pixelSize: 12
                font.weight: 600
                anchors.verticalCenter: parent.verticalCenter
                color: btn._fg
            }
        }
    }

    background: Rectangle {
        radius: Theme.radiusMd
        color: btn._bg
        border.color: btn._border
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        // Subtle highlight glow on hover
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: btn.hovered ? 0.05 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }
}
