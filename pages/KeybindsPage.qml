import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../components"
import "../services"

Item {
    id: page

    property var binds: []

    function loadFromStore() {
        var arr = SettingsStore.get("keybinds", []) || [];
        page.binds = JSON.parse(JSON.stringify(arr));
    }
    Component.onCompleted: loadFromStore()
    Connections {
        target: SettingsStore
        function onChanged() { page.loadFromStore() }
    }

    property var typeOptions: ["bind", "binde", "bindm", "bindl", "bindr"]
    property var dispatcherOptions: [
        "exec", "exec-once", "dispatch",
        "workspace", "movetoworkspace", "movetoworkspacesilent",
        "movewindow", "movefocus", "resizeactive",
        "killactive", "fullscreen", "togglefloating", "pin",
        "togglesplit", "cyclenext", "pseudo", "swapwindow",
        "togglespecialworkspace", "focuscurrentorlast", "layoutmsg"
    ]

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
                placeholderText: "Search keybinds (mods, key, dispatcher, command)…"
            }

            StyledButton {
                variant: "solid"
                text: "Add Keybind"
                iconText: "󰐕"
                onClicked: {
                    var arr = page.binds.slice();
                    arr.unshift({
                        type: "bind", mods: "", key: "",
                        dispatcher: "exec", command: "", isEditing: true
                    });
                    page.binds = arr;
                    SettingsStore.setArray("keybinds", arr);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: page.binds.length + " keybinds configured"
                color: Theme.subtext1
                font.family: Theme.fontUI
                font.pixelSize: 11
                font.weight: 500
            }
            Item { Layout.fillWidth: true }
        }

        // ── Scrollable Keybind List ────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: page.binds

                    delegate: Rectangle {
                        id: row
                        property int idx: index
                        property var b: modelData
                        readonly property bool matches: {
                            var q = search.text.toLowerCase();
                            if (!q) return true;
                            return (b.mods + " " + b.key + " " + b.dispatcher + " " + b.command + " " + b.type).toLowerCase().indexOf(q) >= 0;
                        }
                        visible: matches
                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + 24

                        radius: Theme.radiusMd
                        color: b.isEditing ? Theme.surface1 : Theme.surface0
                        border.color: b.isEditing ? Theme.accent : (rowHoverMa.containsMouse ? Theme.borderHi : Theme.border)
                        border.width: 1

                        transform: Translate {
                            y: rowHoverMa.containsMouse && !b.isEditing ? -2 : 0
                            Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

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

                                // Type Tag
                                Rectangle {
                                    height: 22
                                    width: typeLabel.implicitWidth + 12
                                    radius: 4
                                    color: Theme.surface2
                                    border.color: Theme.border
                                    border.width: 1
                                    Text {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: b.type || "bind"
                                        color: Theme.subtext0
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                // Shortcut Badges
                                RowLayout {
                                    spacing: 4

                                    Rectangle {
                                        visible: (b.mods || "").length > 0
                                        height: 24
                                        width: modLabel.implicitWidth + 14
                                        radius: 5
                                        color: Theme.surface2
                                        border.color: Theme.borderHi
                                        border.width: 1
                                        Text {
                                            id: modLabel
                                            anchors.centerIn: parent
                                            text: b.mods
                                            color: Theme.text
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        visible: (b.mods || "").length > 0 && (b.key || "").length > 0
                                        text: "+"
                                        color: Theme.subtext1
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    Rectangle {
                                        visible: (b.key || "").length > 0
                                        height: 24
                                        width: keyLabel.implicitWidth + 14
                                        radius: 5
                                        color: Theme.surface1
                                        border.color: Theme.borderHi
                                        border.width: 1
                                        Text {
                                            id: keyLabel
                                            anchors.centerIn: parent
                                            text: b.key
                                            color: Theme.text
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                // Dispatcher Badge
                                Rectangle {
                                    height: 20
                                    width: dispLabel.implicitWidth + 10
                                    radius: 4
                                    color: Theme.surface2
                                    border.color: Theme.border
                                    border.width: 1
                                    Text {
                                        id: dispLabel
                                        anchors.centerIn: parent
                                        text: b.dispatcher || "exec"
                                        color: Theme.subtext0
                                        font.family: Theme.fontUI
                                        font.pixelSize: 10
                                    }
                                }

                                // Command preview
                                Text {
                                    text: b.command || "(no command)"
                                    color: b.command ? Theme.subtext0 : Theme.textMuted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Expand Chevron
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: expHoverMa.containsMouse ? Theme.surface2 : "transparent"
                                    scale: expHoverMa.pressed ? 0.88 : (expHoverMa.containsMouse ? 1.25 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅂"
                                        color: b.isEditing ? Theme.accent : Theme.subtext1
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 14
                                        rotation: b.isEditing ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    }

                                    MouseArea {
                                        id: expHoverMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { isEditing: !arr[row.idx].isEditing });
                                            page.binds = arr;
                                        }
                                    }
                                }
                            }

                            // ── Expanded Editor Form ───────────────
                            ColumnLayout {
                                id: editLayout
                                Layout.fillWidth: true
                                visible: b.isEditing
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.border
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    StyledCombo {
                                        id: typeCombo
                                        Layout.preferredWidth: 120
                                        model: page.typeOptions
                                        currentIndex: Math.max(0, page.typeOptions.indexOf(row.b.type))
                                        onActivated: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { type: page.typeOptions[currentIndex] });
                                            page.binds = arr;
                                        }
                                    }

                                    StyledCombo {
                                        id: dispCombo
                                        Layout.preferredWidth: 200
                                        model: page.dispatcherOptions
                                        currentIndex: Math.max(0, page.dispatcherOptions.indexOf(row.b.dispatcher))
                                        onActivated: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { dispatcher: page.dispatcherOptions[currentIndex] });
                                            page.binds = arr;
                                        }
                                    }

                                    StyledTextField {
                                        Layout.preferredWidth: 170
                                        text: row.b.mods
                                        placeholderText: "Modifiers (e.g. )"
                                        onEditingFinished: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { mods: text });
                                            page.binds = arr;
                                        }
                                    }

                                    StyledTextField {
                                        Layout.fillWidth: true
                                        text: row.b.key
                                        placeholderText: "Key (e.g. Return, Q, Space)"
                                        onEditingFinished: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { key: text });
                                            page.binds = arr;
                                        }
                                    }
                                }

                                StyledTextField {
                                    id: cmdField
                                    Layout.fillWidth: true
                                    text: row.b.command
                                    placeholderText: "Command or dispatcher argument"
                                    onEditingFinished: {
                                        var arr = page.binds.slice();
                                        arr[row.idx] = Object.assign({}, arr[row.idx], { command: text });
                                        page.binds = arr;
                                    }
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
                                            var arr = page.binds.slice();
                                            arr.splice(row.idx, 1);
                                            page.binds = arr;
                                            SettingsStore.setArray("keybinds", arr);
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    StyledButton {
                                        variant: "ghost"
                                        text: "Close"
                                        iconText: "󰅖"
                                        onClicked: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], { isEditing: false });
                                            page.binds = arr;
                                        }
                                    }

                                    StyledButton {
                                        variant: "solid"
                                        text: "Save"
                                        iconText: "󰄬"
                                        onClicked: {
                                            var arr = page.binds.slice();
                                            arr[row.idx] = Object.assign({}, arr[row.idx], {
                                                command: cmdField.text,
                                                isEditing: false
                                            });
                                            page.binds = arr;
                                            SettingsStore.setArray("keybinds", arr);
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
