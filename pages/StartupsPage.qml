import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../components"
import "../services"

Item {
    id: page
    property var items: []

    function loadFromStore() {
        var arr = SettingsStore.get("startup", []) || [];
        page.items = JSON.parse(JSON.stringify(arr));
        for (var i = 0; i < page.items.length; i++) {
            if (page.items[i].isEditing === undefined)
                page.items[i].isEditing = false;
        }
    }
    Component.onCompleted: loadFromStore()
    Connections { target: SettingsStore; function onChanged() { page.loadFromStore() } }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ── Header Actions ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledTextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search startup commands…"
            }

            StyledButton {
                variant: "solid"
                text: "Add Command"
                iconText: "󰐕"
                onClicked: {
                    var arr = page.items.slice();
                    arr.unshift({ command: "", isEditing: true });
                    page.items = arr;
                    SettingsStore.setArray("startup", arr);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: page.items.length + " startup items configured"
                color: Theme.textMuted
                font.family: Theme.fontUI
                font.pixelSize: 11
                font.weight: 500
            }
            Item { Layout.fillWidth: true }
        }

        // ── Scrollable Startup List ────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: page.items

                    delegate: Rectangle {
                        id: row
                        property int idx: index
                        property var it: modelData
                        readonly property bool isCommented: (it.command || "").trim().startsWith("#")
                        readonly property bool matches: {
                            var q = search.text.toLowerCase();
                            if (!q) return true;
                            return (it.command || "").toLowerCase().indexOf(q) >= 0;
                        }
                        visible: matches
                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + 24

                        radius: Theme.radiusMd
                        color: it.isEditing ? Theme.surface1 : Theme.surface0
                        border.color: it.isEditing ? Theme.accent : (rowHoverMa.containsMouse ? Theme.borderHi : Theme.border)
                        border.width: 1
                        transform: Translate {
                            y: rowHoverMa.containsMouse && !it.isEditing ? -2 : 0
                            Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        }
                        opacity: isCommented && !it.isEditing ? 0.6 : 1.0

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            id: cardCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 12

                            // ── Row Header ─────────────────────────
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Order Badge
                                Rectangle {
                                    width: 26
                                    height: 24
                                    radius: 5
                                    color: Theme.surface2
                                    Text {
                                        anchors.centerIn: parent
                                        text: "#" + (row.idx + 1)
                                        color: Theme.textMuted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                // Status Dot
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: isCommented ? Theme.textMuted : "#27c93f"
                                }

                                // Command Preview
                                Text {
                                    text: isCommented ? (it.command || "").replace(/^#\s*/, "") + " (disabled)" : (it.command || "(empty command)")
                                    color: isCommented ? Theme.textMuted : (it.command ? Theme.text : Theme.textMuted)
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Reorder Buttons (Clean separate icons)
                                RowLayout {
                                    spacing: 4

                                    // Up Button
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 5
                                        color: upMa.containsMouse && row.idx > 0 ? Theme.surface2 : "transparent"
                                        opacity: row.idx === 0 ? 0.3 : 1.0

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰜸"
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 13
                                            color: upMa.containsMouse ? Theme.accent : Theme.subtext0
                                            anchors.verticalCenterOffset: upMa.containsMouse ? -3 : 0
                                            scale: upMa.pressed ? 0.85 : (upMa.containsMouse ? 1.25 : 1.0)
                                            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                        }

                                        MouseArea {
                                            id: upMa
                                            anchors.fill: parent
                                            hoverEnabled: row.idx > 0
                                            cursorShape: row.idx > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (row.idx === 0) return;
                                                var arr = page.items.slice();
                                                var tmp = arr[row.idx - 1];
                                                arr[row.idx - 1] = arr[row.idx];
                                                arr[row.idx] = tmp;
                                                page.items = arr;
                                                SettingsStore.setArray("startup", arr);
                                            }
                                        }
                                    }

                                    // Down Button
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 5
                                        color: dnMa.containsMouse && row.idx < page.items.length - 1 ? Theme.surface2 : "transparent"
                                        opacity: row.idx >= page.items.length - 1 ? 0.3 : 1.0

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰜯"
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 13
                                            color: dnMa.containsMouse ? Theme.accent : Theme.subtext0
                                            anchors.verticalCenterOffset: dnMa.containsMouse ? 3 : 0
                                            scale: dnMa.pressed ? 0.85 : (dnMa.containsMouse ? 1.25 : 1.0)
                                            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                        }

                                        MouseArea {
                                            id: dnMa
                                            anchors.fill: parent
                                            hoverEnabled: row.idx < page.items.length - 1
                                            cursorShape: row.idx < page.items.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (row.idx >= page.items.length - 1) return;
                                                var arr = page.items.slice();
                                                var tmp = arr[row.idx + 1];
                                                arr[row.idx + 1] = arr[row.idx];
                                                arr[row.idx] = tmp;
                                                page.items = arr;
                                                SettingsStore.setArray("startup", arr);
                                            }
                                        }
                                    }
                                }

                                // Expand Chevron
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: expMa.containsMouse ? Theme.surface2 : "transparent"
                                    scale: expMa.pressed ? 0.88 : (expMa.containsMouse ? 1.25 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅂"
                                        color: it.isEditing ? Theme.accent : Theme.subtext1
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 14
                                        rotation: it.isEditing ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    }

                                    MouseArea {
                                        id: expMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var arr = page.items.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { isEditing: !arr[row.idx].isEditing });
                                            page.items = arr;
                                        }
                                    }
                                }
                            }

                            // ── Expanded Editor Form ───────────────
                            ColumnLayout {
                                id: editCol
                                Layout.fillWidth: true
                                visible: it.isEditing
                                spacing: 12

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.border
                                }

                                StyledTextField {
                                    id: cmdField
                                    Layout.fillWidth: true
                                    text: row.it.command
                                    placeholderText: "Command to run on startup (e.g. quickshell -p ...)"
                                    onEditingFinished: {
                                        var arr = page.items.slice();
                                        arr[row.idx] = Object.assign({}, arr[row.idx], { command: text });
                                        page.items = arr;
                                    }
                                }

                                // Quick Enable / Disable Action Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // Toggle Enable Pill
                                    Rectangle {
                                        height: 30
                                        width: toggleRow.implicitWidth + 20
                                        radius: Theme.radiusSm
                                        color: toggleMa.containsMouse ? Theme.surface2 : Theme.surface1
                                        border.color: isCommented ? Theme.border : "#27c93f"
                                        border.width: 1
                                        scale: toggleMa.pressed ? 0.92 : (toggleMa.containsMouse ? 1.06 : 1.0)
                                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                                        RowLayout {
                                            id: toggleRow
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Rectangle {
                                                width: 6; height: 6; radius: 3
                                                color: isCommented ? Theme.textMuted : "#27c93f"
                                            }

                                            Text {
                                                text: isCommented ? "Disabled (Click to Enable)" : "Active at Boot"
                                                color: isCommented ? Theme.textMuted : Theme.text
                                                font.family: Theme.fontUI
                                                font.pixelSize: 11
                                                font.weight: 500
                                            }
                                        }

                                        MouseArea {
                                            id: toggleMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var raw = (cmdField.text || "").trim();
                                                var newCmd = raw;
                                                if (raw.startsWith("#")) {
                                                    newCmd = raw.replace(/^#\s*/, "");
                                                } else {
                                                    newCmd = "# " + raw;
                                                }
                                                cmdField.text = newCmd;
                                                var arr = page.items.slice();
                                                arr[row.idx] = Object.assign({}, arr[row.idx], { command: newCmd });
                                                page.items = arr;
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // ── Action Buttons Cleanly Aligned ─
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    StyledButton {
                                        variant: "danger"
                                        text: "Delete"
                                        iconText: "󰆴"
                                        onClicked: {
                                            var arr = page.items.slice();
                                            arr.splice(row.idx, 1);
                                            page.items = arr;
                                            SettingsStore.setArray("startup", arr);
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    StyledButton {
                                        variant: "ghost"
                                        text: "Close"
                                        iconText: "󰅖"
                                        onClicked: {
                                            var arr = page.items.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { isEditing: false });
                                            page.items = arr;
                                        }
                                    }

                                    StyledButton {
                                        variant: "solid"
                                        text: "Save"
                                        iconText: "󰄬"
                                        onClicked: {
                                            var arr = page.items.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], {
                                                command: cmdField.text,
                                                isEditing: false
                                            });
                                            page.items = arr;
                                            SettingsStore.setArray("startup", arr);
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowHoverMa
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
