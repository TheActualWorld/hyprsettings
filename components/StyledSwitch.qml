import QtQuick
import QtQuick.Controls
import "../"

Switch {
    id: sw
    implicitWidth: 46
    implicitHeight: 26
    hoverEnabled: true

    indicator: Rectangle {
        implicitWidth: 46
        implicitHeight: 26
        x: 0; y: (sw.height - height)/2
        radius: 13
        color: sw.checked ? Theme.accent : Theme.surface2
        border.color: sw.checked ? Theme.accentHover : Theme.border
        border.width: 1
        Behavior on color        { ColorAnimation { duration: Theme.animMed } }
        Behavior on border.color { ColorAnimation { duration: Theme.animMed } }

        Rectangle {
            x: sw.checked ? parent.width - width - 3 : 3
            y: (parent.height - height)/2
            width: 20; height: 20; radius: 10
            color: sw.checked ? Theme.crust : Theme.text
            Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }

            // subtle inner shadow
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: Qt.rgba(0,0,0,0.10)
                border.width: 1
            }
        }
    }
    contentItem: Item {}
}
