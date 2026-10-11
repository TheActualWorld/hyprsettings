//
// Standalone Settings Window for Hyprland
// Run with:  quickshell -p ~/.config/hypr/scripts/quickshell/settings_window
//
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./services"
import "./components"
import "./pages"
import "."

FloatingWindow {
    id: win
    title: (SysInfo.de || "Hyprland") + " Settings"
    implicitWidth: 1200
    implicitHeight: 780
    color: Theme.bg

    property int currentPage: 0
    property bool isReloading: false

    Component.onCompleted: SettingsStore.reload()

    Process {
        id: compileProc
        running: false
        command: ["bash", "-c", "if [ -f ~/.config/hypr/scripts/settings_watcher.sh ]; then bash ~/.config/hypr/scripts/settings_watcher.sh --compile; fi"]
        onExited: {
            SettingsStore.reload()
            win.isReloading = false
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //  Root
    // ═══════════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: Theme.bg

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ═══════════════════════════════════════════════════════════
            //  SIDEBAR
            // ═══════════════════════════════════════════════════════════
            Rectangle {
                id: sidebar
                Layout.preferredWidth: 246
                Layout.fillHeight: true
                color: Theme.sidebar

                // Right divider line
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.border
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 18
                    anchors.bottomMargin: 16
                    spacing: 6

                    // ── macOS Window Dots / Header Controls ──────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 14
                        spacing: 10

                        // Red close dot
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: closeDotMa.containsMouse ? "#ff5f56" : "#ff5f56"
                            border.color: "#e0443e"
                            border.width: 1
                            scale: closeDotMa.pressed ? 0.88 : (closeDotMa.containsMouse ? 1.15 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 8
                                font.bold: true
                                color: "#4c0000"
                                visible: closeDotMa.containsMouse
                            }

                            MouseArea {
                                id: closeDotMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.quit()
                            }
                        }

                        // Yellow minimize / subtle dot
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "#ffbd2e"
                            border.color: "#dea123"
                            border.width: 1
                        }

                        // Green reload dot
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "#27c93f"
                            border.color: "#1aab29"
                            border.width: 1
                            scale: greenDotMa.pressed ? 0.88 : (greenDotMa.containsMouse ? 1.15 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                            Text {
                                anchors.centerIn: parent
                                text: "↻"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#004d00"
                                visible: greenDotMa.containsMouse
                            }

                            MouseArea {
                                id: greenDotMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.isReloading = true
                                    SettingsStore.reload()
                                    compileProc.running = true
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // ── Brand Header ─────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 16
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: Theme.radiusMd
                            color: Theme.surface0
                            border.color: Theme.borderHi
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰣇"
                                font.family: Theme.fontIcon
                                font.pixelSize: 22
                                color: Theme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: SysInfo.de || "Hyprland"
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 15
                                font.weight: 700
                            }
                            Text {
                                text: SysInfo.host ? ("@" + SysInfo.host) : "System Control"
                                color: Theme.subtext1
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                font.weight: 500
                            }
                        }
                    }

                    // ── Section label ────────────────────────────────
                    Text {
                        text: "NAVIGATION"
                        color: Theme.textMuted
                        font.family: Theme.fontUI
                        font.pixelSize: 10
                        font.weight: 700
                        font.letterSpacing: 1.2
                        Layout.leftMargin: 8
                        Layout.bottomMargin: 4
                    }

                    NavItem {
                        Layout.fillWidth: true
                        iconText: "󰣇"
                        label: "General"
                        active: win.currentPage === 0
                        onClicked: win.currentPage = 0
                    }
                    NavItem {
                        Layout.fillWidth: true
                        iconText: "󰌌"
                        label: "Keybinds"
                        active: win.currentPage === 1
                        onClicked: win.currentPage = 1
                    }
                    NavItem {
                        Layout.fillWidth: true
                        iconText: "󰐥"
                        label: "Startups"
                        active: win.currentPage === 2
                        onClicked: win.currentPage = 2
                    }
                    NavItem {
                        Layout.fillWidth: true
                        iconText: "󰍹"
                        label: "Monitors"
                        active: win.currentPage === 3
                        onClicked: win.currentPage = 3
                    }

                    Item { Layout.fillHeight: true }

                    // ── Footer System Action Bar ─────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                        Layout.bottomMargin: 6
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Modern Reload Pill
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Theme.radiusMd
                            color: reloadBtnMa.containsMouse ? Theme.surface2 : Theme.surface0
                            border.color: reloadBtnMa.containsMouse ? Theme.borderHi : Theme.border
                            border.width: 1
                            scale: reloadBtnMa.pressed ? 0.95 : (reloadBtnMa.containsMouse ? 1.02 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    id: reloadIcon
                                    text: "󰑐"
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 14
                                    color: win.isReloading ? Theme.accent : Theme.text
                                    rotation: win.isReloading ? 360 : 0
                                    Behavior on rotation {
                                        NumberAnimation { duration: 800; loops: Animation.Infinite; running: win.isReloading }
                                    }
                                }

                                Text {
                                    text: win.isReloading ? "Compiling…" : "Reload"
                                    color: Theme.text
                                    font.family: Theme.fontUI
                                    font.pixelSize: 12
                                    font.weight: 600
                                }
                            }

                            MouseArea {
                                id: reloadBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    win.isReloading = true
                                    SettingsStore.reload()
                                    compileProc.running = true
                                }
                            }
                        }

                        // Modern Close Pill
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: Theme.radiusMd
                            color: closeBtnMa.containsMouse ? Qt.rgba(1.0, 0.25, 0.25, 0.22) : Theme.surface0
                            border.color: closeBtnMa.containsMouse ? Qt.rgba(1.0, 0.25, 0.25, 0.45) : Theme.border
                            border.width: 1
                            scale: closeBtnMa.pressed ? 0.93 : (closeBtnMa.containsMouse ? 1.05 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Theme.fontIcon
                                font.pixelSize: 14
                                color: closeBtnMa.containsMouse ? "#ff6e6e" : Theme.subtext0
                            }

                            MouseArea {
                                id: closeBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.quit()
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════
            //  ANIMATED SLIDING CONTENT CONTAINER
            // ═══════════════════════════════════════════════════════════
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bg
                clip: true

                Item {
                    id: pageContainer
                    anchors.fill: parent
                    anchors.margins: 24

                    property int activePage: win.currentPage
                    property int lastPage: 0
                    property real pageXOffset: 0
                    property real pageAlpha: 1.0

                    onActivePageChanged: {
                        var dir = activePage >= lastPage ? 1 : -1
                        lastPage = activePage
                        pageAnim.stop()
                        pageXOffset = dir * 36
                        pageAlpha = 0.0
                        pageAnim.start()
                    }

                    ParallelAnimation {
                        id: pageAnim
                        NumberAnimation {
                            target: pageContainer
                            property: "pageXOffset"
                            to: 0
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pageContainer
                            property: "pageAlpha"
                            to: 1.0
                            duration: 220
                            easing.type: Easing.OutQuad
                        }
                    }

                    Item {
                        anchors.fill: parent
                        x: pageContainer.pageXOffset
                        opacity: pageContainer.pageAlpha

                        Loader {
                            anchors.fill: parent
                            sourceComponent: {
                                switch (win.currentPage) {
                                    case 0: return generalComp
                                    case 1: return keybindsComp
                                    case 2: return startupsComp
                                    case 3: return monitorsComp
                                    default: return generalComp
                                }
                            }
                        }
                    }

                    Component { id: generalComp; GeneralPage {} }
                    Component { id: keybindsComp; KeybindsPage {} }
                    Component { id: startupsComp; StartupsPage {} }
                    Component { id: monitorsComp; MonitorsPage {} }
                }
            }
        }
    }
}
