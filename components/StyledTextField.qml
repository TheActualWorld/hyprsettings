import QtQuick
import QtQuick.Controls
import "../"

TextField {
    id: tf
    color: Theme.text
    selectionColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.20)
    selectedTextColor: Theme.text
    placeholderTextColor: Theme.subtext1
    font.family: Theme.fontUI
    font.pixelSize: 13
    padding: 9
    leftPadding: 14
    rightPadding: 14
    implicitHeight: 36
    hoverEnabled: true

    background: Rectangle {
        radius: Theme.radiusSm
        color: tf.activeFocus ? Theme.surface2
                              : (tf.hovered ? Theme.surface2 : Theme.surface1)
        border.color: tf.activeFocus ? Theme.accent : Theme.border
        border.width: 1
        Behavior on color        { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }
}
