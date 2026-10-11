import QtQuick
import "../"

Rectangle {
    id: root
    color: Theme.surface0
    radius: Theme.radiusLg
    border.color: Theme.border
    border.width: 1

    property int contentMargin: 18
    default property alias content: inner.data

    // Subtle inner highlight along the top edge — very light, tasteful.
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 1
        height: 1
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.03)
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.contentMargin
    }
}
