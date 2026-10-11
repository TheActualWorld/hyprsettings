import QtQuick
import QtQuick.Controls
import "../"

ComboBox {
    id: cb
    font.family: Theme.fontUI
    font.pixelSize: 13
    padding: 8
    leftPadding: 14
    rightPadding: 32
    implicitHeight: 36
    hoverEnabled: true

    delegate: ItemDelegate {
        width: cb.width
        padding: 6
        contentItem: Text {
            text: modelData
            color: highlighted ? Theme.accent : Theme.text
            font.family: Theme.fontUI
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
        }
        background: Rectangle {
            radius: Theme.radiusSm
            color: hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        }
        highlighted: cb.highlightedIndex === index
    }

    indicator: Text {
        text: "▾"
        color: cb.hovered ? Theme.text : Theme.subtext1
        font.pixelSize: 11
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    contentItem: Text {
        text: cb.displayText
        color: Theme.text
        font.family: Theme.fontUI
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: cb.hovered ? Theme.surface2 : Theme.surface1
        border.color: cb.activeFocus ? Theme.accent : Theme.border
        border.width: 1
        Behavior on color        { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    }

    popup: Popup {
        y: cb.height + 6
        width: cb.width
        implicitHeight: Math.min(320, contentItem.implicitHeight + 12)
        padding: 6
        background: Rectangle {
            color: Theme.surface1
            border.color: Theme.borderHi
            border.width: 1
            radius: Theme.radiusMd
        }
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: cb.popup.visible ? cb.delegateModel : null
            currentIndex: cb.highlightedIndex
            ScrollBar.vertical: ScrollBar {}
        }
    }
}
