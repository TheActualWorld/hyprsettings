import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../components"
import "../services"

ScrollView {
    id: page
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    readonly property string settingsLaunchCmd: "quickshell -p ~/.config/hypr/scripts/quickshell/settings_window"
    property bool startupHasSettingsWindow: false

    function refreshStartupFlag() {
        var arr = SettingsStore.get("startup", []) || [];
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].command === page.settingsLaunchCmd) {
                page.startupHasSettingsWindow = true;
                return;
            }
        }
        page.startupHasSettingsWindow = false;
    }
    Component.onCompleted: page.refreshStartupFlag()
    Connections {
        target: SettingsStore
        function onChanged() { page.refreshStartupFlag() }
    }

    ColumnLayout {
        width: page.availableWidth - 14
        spacing: 16

        // ── User / System Card ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: infoRow.implicitHeight + 40
            radius: Theme.radiusLg
            color: Theme.surface0
            border.color: Theme.border
            border.width: 1

            RowLayout {
                id: infoRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 20

                // ── Default Avatar (Inscribed & Proportional) ───────
                Item {
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 84
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 42
                        color: Theme.surface1
                        border.color: Theme.borderHi
                        border.width: 1

                        Image {
                            anchors.fill: parent
                            source: SysInfo.avatar.length > 0 ? ("file://" + SysInfo.avatar) : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: SysInfo.avatar.length > 0
                        }

                        Item {
                            anchors.fill: parent
                            visible: SysInfo.avatar.length === 0

                            // Head: 30x30, centered at y=14
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: Theme.text
                                opacity: 0.94
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 14
                            }

                            // Body: 54x34, radius 18, centered at y=48
                            Rectangle {
                                width: 54
                                height: 34
                                radius: 18
                                color: Theme.text
                                opacity: 0.94
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 48
                            }
                        }
                    }

                    // Online / Active Indicator
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: 14
                        height: 14
                        radius: 7
                        color: "#27c93f"
                        border.color: Theme.surface0
                        border.width: 2
                    }
                }

                // ── User & Hardware Info Column ───────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        spacing: 8
                        Text {
                            text: SysInfo.user
                            font.family: Theme.fontBrand
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: Theme.text
                        }

                        // Desktop Environment Badge
                        Rectangle {
                            height: 20
                            width: deBadgeText.implicitWidth + 12
                            radius: 10
                            color: Theme.surface2
                            border.color: Theme.border
                            border.width: 1

                            Text {
                                id: deBadgeText
                                anchors.centerIn: parent
                                text: SysInfo.de || "Hyprland"
                                color: Theme.accent
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        text: "@" + (SysInfo.host || "localhost")
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: Theme.subtext1
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        height: 1
                        color: Theme.border
                    }

                    // Specs Row 1: Distro + Kernel
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰣇"
                                font.family: Theme.fontIcon; font.pixelSize: 14
                                color: Theme.accent
                            }
                            Text {
                                text: SysInfo.distro || "Linux"
                                font.family: Theme.fontUI; font.pixelSize: 12
                                color: Theme.subtext0
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰌽"
                                font.family: Theme.fontIcon; font.pixelSize: 14
                                color: Theme.subtext1
                            }
                            Text {
                                text: SysInfo.kernel || ""
                                font.family: Theme.fontMono; font.pixelSize: 12
                                color: Theme.subtext0
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Specs Row 2: CPU + GPU
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 20

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: "󰍛"
                                font.family: Theme.fontIcon; font.pixelSize: 14
                                color: Theme.accent
                            }
                            Text {
                                Layout.fillWidth: true
                                text: SysInfo.cpu || "CPU"
                                font.family: Theme.fontMono; font.pixelSize: 11
                                color: Theme.subtext0
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: "󰢮"
                                font.family: Theme.fontIcon; font.pixelSize: 14
                                color: Theme.subtext1
                            }
                            Text {
                                Layout.fillWidth: true
                                text: SysInfo.gpu || "GPU"
                                font.family: Theme.fontMono; font.pixelSize: 11
                                color: Theme.subtext0
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ── Theme Selection Card ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: themeCol.implicitHeight + 36
            radius: Theme.radiusLg
            color: Theme.surface0
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: themeCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Appearance & Theme"
                        font.family: Theme.fontUI
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.text
                    }
                    Text {
                        text: "Select a color theme for Quickshell and system controls"
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        color: Theme.subtext1
                    }
                }

                // Grid of Theme Cards
                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { id: "black", name: "Pitch Black", desc: "Obsidian Monochrome", bg: "#000000", card: "#0e0e0e", accent: "#ffffff" },
                            { id: "white", name: "Pure White",  desc: "Clean Monochrome",   bg: "#f8f9fa", card: "#ffffff", accent: "#111827" }
                        ]

                        Rectangle {
                            id: themeCard
                            property bool isSelected: (Theme.currentTheme === modelData.id)
                            width: 210
                            height: 72
                            radius: Theme.radiusMd
                            color: isSelected ? Theme.surface2 : Theme.surface1
                            border.color: isSelected ? Theme.accent : (themeCardMa.containsMouse ? Theme.borderHi : Theme.border)
                            border.width: isSelected ? 2 : 1

                            transform: Translate {
                                y: themeCardMa.containsMouse && !themeCard.isSelected ? -2 : 0
                                Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                            }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    // Palette preview dots
                                    Row {
                                        spacing: 4
                                        Rectangle { width: 12; height: 12; radius: 6; color: modelData.bg; border.color: "#444444"; border.width: 0.5 }
                                        Rectangle { width: 12; height: 12; radius: 6; color: modelData.card; border.color: "#444444"; border.width: 0.5 }
                                        Rectangle { width: 12; height: 12; radius: 6; color: modelData.accent }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Checkmark badge when active
                                    Rectangle {
                                        visible: themeCard.isSelected
                                        width: 16; height: 16; radius: 8
                                        color: Theme.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰄬"
                                            font.family: Theme.fontIcon
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.base
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontUI
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: themeCard.isSelected ? Theme.text : Theme.subtext0
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: Theme.fontUI
                                    font.pixelSize: 10
                                    color: Theme.subtext1
                                }
                            }

                            MouseArea {
                                id: themeCardMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsStore.set("theme", modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ── Preferences ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            radius: Theme.radiusLg
            color: Theme.surface0
            border.color: Theme.border; border.width: 1
            implicitHeight: prefCol.implicitHeight + 36

            ColumnLayout {
                id: prefCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 14

                Text {
                    text: "Preferences"
                    font.family: Theme.fontUI; font.pixelSize: 14; font.weight: Font.Bold
                    color: Theme.subtext0
                }

                component PrefRow: RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    property alias label: lbl.text
                    property alias hint:  hnt.text
                    property int slotWidth: 260
                    default property alias inner: rightSlot.data
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { id: lbl; font.family: Theme.fontUI; font.pixelSize: 13; color: Theme.text }
                        Text { id: hnt; font.family: Theme.fontUI; font.pixelSize: 11; color: Theme.overlay1; wrapMode: Text.Wrap }
                    }
                    Item { id: rightSlot; Layout.preferredWidth: slotWidth; Layout.preferredHeight: 34 }
                }

                PrefRow {
                    label: "Wallpaper directory"
                    hint:  "Folder used for wallpaper cycling"
                    StyledTextField {
                        anchors.fill: parent
                        text: SettingsStore.get("wallpaperDir", "")
                        onEditingFinished: SettingsStore.set("wallpaperDir", text)
                    }
                }

                PrefRow {
                    label: "Keyboard layouts"
                    hint:  "Comma separated, e.g. us,ir"
                    StyledTextField {
                        anchors.fill: parent
                        text: SettingsStore.get("language", "us")
                        onEditingFinished: SettingsStore.set("language", text)
                    }
                }

                PrefRow {
                    label: "Keyboard options"
                    hint:  "xkb options string"
                    StyledTextField {
                        anchors.fill: parent
                        text: SettingsStore.get("kbOptions", "")
                        onEditingFinished: SettingsStore.set("kbOptions", text)
                    }
                }

                PrefRow {
                    label: "Open settings window on startup"
                    hint:  "Adds/removes this window from your startup commands"
                    slotWidth: 52
                    RowLayout {
                        anchors.fill: parent
                        Item { Layout.fillWidth: true }
                        StyledSwitch {
                            checked: page.startupHasSettingsWindow
                            onToggled: {
                                var cmd = page.settingsLaunchCmd;
                                var arr = (SettingsStore.get("startup", []) || []).slice();
                                var idx = -1;
                                for (var i = 0; i < arr.length; i++)
                                    if (arr[i].command === cmd) { idx = i; break; }

                                if (checked && idx === -1) {
                                    arr.push({ command: cmd, isEditing: false });
                                    SettingsStore.setArray("startup", arr);
                                } else if (!checked && idx !== -1) {
                                    arr.splice(idx, 1);
                                    SettingsStore.setArray("startup", arr);
                                }
                                page.refreshStartupFlag();
                            }
                        }
                    }
                }
            }
        }
    }
}
