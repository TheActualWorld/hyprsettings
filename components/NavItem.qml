import QtQuick
import QtQuick.Layouts
import "../"

Item {
    id: root
    implicitHeight: 46
    Layout.fillWidth: true

    signal clicked()
    property string label:      ""
    property string icon:       ""
    property alias  iconText:   root.icon
    property string iconFamily: ""
    property bool   active:     false

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.leftMargin: 6; anchors.rightMargin: 6
        anchors.topMargin: 2;  anchors.bottomMargin: 2
        radius: Theme.radiusMd
        color: root.active ? Qt.rgba(1, 1, 1, 0.10)
                           : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.color: root.active ? Qt.rgba(1, 1, 1, 0.22) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.width: 1

        scale: ma.pressed ? 0.96 : (ma.containsMouse ? 1.02 : 1.0)
        Behavior on scale        { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
        Behavior on color        { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        // Left accent indicator bar with spring bounce
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: -1
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: root.active ? 22 : (ma.containsMouse ? 12 : 0)
            radius: 2
            color: Theme.accent
            opacity: root.active ? 1.0 : (ma.containsMouse ? 0.6 : 0.0)
            Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 12

            Text {
                id: iconGlyph
                text: root.icon
                font.family: root.iconFamily.length > 0 ? root.iconFamily : Theme.fontIcon
                font.pixelSize: 17
                color: root.active ? Theme.accent
                                   : (ma.containsMouse ? Theme.text : Theme.subtext1)
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter

                scale: ma.pressed ? 0.90 : (ma.containsMouse ? 1.20 : (root.active ? 1.10 : 1.0))
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                text: root.label
                font.family: Theme.fontUI
                font.pixelSize: 13
                font.weight: root.active ? 600 : 500
                color: root.active ? Theme.text
                                   : (ma.containsMouse ? Theme.text : Theme.subtext0)
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Text {
                text: "›"
                font.family: Theme.fontUI
                font.pixelSize: 16
                font.weight: 600
                color: root.active ? Theme.accent : (ma.containsMouse ? Theme.subtext1 : "transparent")
                scale: ma.containsMouse ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
