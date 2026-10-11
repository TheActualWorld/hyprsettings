import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../services"
import "../components"

Item {
    id: root
    anchors.fill: parent

    property var monitors: []
    property int selectedIndex: 0
    property var selected: monitors.length > selectedIndex && selectedIndex >= 0 ? monitors[selectedIndex] : null

    // Real hardware modes queried live from hyprctl: name -> [{ w, h, rates: [] }]
    property var hwModes: ({})
    property var liveMonNames: []
    property real userZoom: 1.0

    function loadAndSync() {
        hwProc.running = false
        hwProc.running = true
    }

    Component.onCompleted: loadAndSync()

    Connections {
        target: SettingsStore
        function onChanged() {
            if (!hwProc.running) {
                var stored = SettingsStore.get("monitors", []) || []
                if (stored.length > 0 && root.monitors.length === 0) {
                    root.monitors = JSON.parse(JSON.stringify(stored))
                }
            }
        }
    }

    function updateMonitor(index, patch) {
        var mons = JSON.parse(JSON.stringify(root.monitors))
        if (!mons[index]) return
        for (var k in patch) mons[index][k] = patch[k]
        root.monitors = mons
        SettingsStore.set("monitors", mons)
    }

    function applyMonitorToHypr(m) {
        if (!m) return
        var arg = m.name + "," + m.resW + "x" + m.resH + "@" + m.rate + "," + m.x + "x" + m.y + "," + m.scale + ",transform," + (m.transform || 0)
        singleApplyProc.command = ["hyprctl", "keyword", "monitor", arg]
        singleApplyProc.running = true
    }

    Process {
        id: singleApplyProc
        running: false
    }

    function parseHwInfo(text) {
        if (!text || text.trim().length === 0) return
        try {
            var arr = JSON.parse(text.trim())
            var map = {}
            var names = []
            var liveList = []

            for (var i = 0; i < arr.length; i++) {
                var m = arr[i]
                names.push(m.name)

                var resMap = {}
                var modes = m.availableModes || []
                for (var j = 0; j < modes.length; j++) {
                    var mode = modes[j]
                    var atIdx = mode.indexOf("@")
                    if (atIdx < 0) continue
                    var resPart = mode.substring(0, atIdx)
                    var rate = parseFloat(mode.substring(atIdx + 1).replace("Hz", ""))
                    if (isNaN(rate)) continue
                    if (!resMap[resPart]) resMap[resPart] = []
                    resMap[resPart].push(rate)
                }

                var resList = []
                for (var key in resMap) {
                    var wh = key.split("x")
                    var rates = resMap[key].slice().sort(function(a, b) { return b - a })
                    resList.push({ w: parseInt(wh[0]), h: parseInt(wh[1]), rates: rates })
                }
                resList.sort(function(a, b) { return (b.w * b.h) - (a.w * a.h) })
                map[m.name] = resList

                liveList.push({
                    name: m.name,
                    resW: m.width || 1920,
                    resH: m.height || 1080,
                    rate: Math.round((m.refreshRate || 60) * 100) / 100,
                    x: m.x || 0,
                    y: m.y || 0,
                    scale: m.scale || 1.0,
                    transform: m.transform || 0,
                    enabled: !m.disabled,
                    isLive: true
                })
            }

            root.hwModes = map
            root.liveMonNames = names

            // Merge saved monitor configs only for currently connected displays
            var stored = JSON.parse(JSON.stringify(SettingsStore.get("monitors", []) || []))
            var finalMons = []

            for (var k = 0; k < liveList.length; k++) {
                var lm = liveList[k]
                var found = null
                for (var s = 0; s < stored.length; s++) {
                    if (stored[s].name === lm.name) {
                        found = stored[s]
                        break
                    }
                }
                if (found) {
                    finalMons.push({
                        name: lm.name,
                        resW: found.resW || lm.resW,
                        resH: found.resH || lm.resH,
                        rate: found.rate || lm.rate,
                        x: found.x !== undefined ? found.x : lm.x,
                        y: found.y !== undefined ? found.y : lm.y,
                        scale: found.scale || lm.scale,
                        transform: found.transform !== undefined ? found.transform : lm.transform,
                        enabled: true,
                        isLive: true
                    })
                } else {
                    finalMons.push(lm)
                }
            }

            root.monitors = finalMons
            SettingsStore.set("monitors", finalMons)

            if (root.selectedIndex >= finalMons.length) root.selectedIndex = 0
        } catch (e) {
            console.warn("MonitorsPage: failed to parse hyprctl monitors -j:", e)
        }
    }

    function modesFor(mon) {
        if (!mon) return []
        var list = root.hwModes[mon.name]
        if (list && list.length) return list
        return [{ w: mon.resW, h: mon.resH, rates: [mon.rate] }]
    }

    function ratesFor(mon, w, h) {
        var list = root.modesFor(mon)
        for (var i = 0; i < list.length; i++) {
            if (list[i].w === w && list[i].h === h) return list[i].rates
        }
        return mon ? [mon.rate] : []
    }

    Process {
        id: hwProc
        running: true
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseHwInfo(this.text)
        }
    }

    ScrollView {
        id: scroller
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroller.availableWidth - 14
            spacing: 16

            // ── Page Header ────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Monitors & Displays"
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: root.monitors.length + " display" + (root.monitors.length === 1 ? "" : "s") + " connected & active"
                        color: Theme.subtext1
                        font.family: Theme.fontUI
                        font.pixelSize: 12
                    }
                }

                StyledButton {
                    variant: "ghost"
                    text: "Detect Displays"
                    iconText: "󰑐"
                    onClicked: root.loadAndSync()
                }
            }

            // ── Monitor Selector Chips ─────────────────────────────
            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.monitors

                    Rectangle {
                        property bool isSel: index === root.selectedIndex
                        width: tabRow.implicitWidth + 24
                        height: 36
                        radius: Theme.radiusMd
                        color: isSel ? Theme.surface2 : Theme.surface0
                        border.color: isSel ? Theme.accent : Theme.border
                        border.width: 1
                        transform: Translate {
                            y: tabMa.containsMouse ? -2 : 0
                            Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                        }
                        scale: tabMa.pressed ? 0.95 : (tabMa.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        RowLayout {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: modelData.isLive ? "#27c93f" : Theme.textMuted
                            }

                            Text {
                                text: modelData.name
                                color: isSel ? Theme.text : Theme.subtext0
                                font.family: Theme.fontUI
                                font.pixelSize: 12
                                font.bold: isSel
                            }

                            Text {
                                text: modelData.resW + "×" + modelData.resH
                                color: Theme.subtext1
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.weight: 500
                            }
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedIndex = index
                        }
                    }
                }
            }

            // ── Displays Arrangement Canvas Card ───────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 460
                radius: Theme.radiusLg
                color: Theme.surface0
                border.color: Theme.border
                border.width: 1
                visible: root.monitors.length > 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Canvas Toolbar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Display Arrangement"
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "Drag to arrange. Monitors magnetically stick to adjacent edges."
                                color: Theme.subtext1
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                            }
                        }

                        // Zoom Controls
                        RowLayout {
                            spacing: 4

                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: zoomOutMa.containsMouse ? Theme.surface2 : Theme.surface1
                                border.color: Theme.border; border.width: 1
                                Text { anchors.centerIn: parent; text: "-"; color: Theme.text; font.pixelSize: 14; font.bold: true }
                                MouseArea {
                                    id: zoomOutMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.userZoom = Math.max(0.6, root.userZoom - 0.15)
                                }
                            }

                            Text {
                                text: Math.round(root.userZoom * 100) + "%"
                                color: Theme.subtext0
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                Layout.preferredWidth: 42
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: zoomInMa.containsMouse ? Theme.surface2 : Theme.surface1
                                border.color: Theme.border; border.width: 1
                                Text { anchors.centerIn: parent; text: "+"; color: Theme.text; font.pixelSize: 14; font.bold: true }
                                MouseArea {
                                    id: zoomInMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.userZoom = Math.min(2.0, root.userZoom + 0.15)
                                }
                            }

                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: zoomResetMa.containsMouse ? Theme.surface2 : Theme.surface1
                                border.color: Theme.border; border.width: 1
                                Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.fontIcon; color: Theme.text; font.pixelSize: 11 }
                                MouseArea {
                                    id: zoomResetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.userZoom = 1.0
                                }
                            }
                        }
                    }

                    // ── The Interactive Arrangement Stage ──────────────
                    Rectangle {
                        id: canvas
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.canvasBg
                        border.color: Theme.border
                        border.width: 1
                        clip: true

                        // Subtle Grid Pattern
                        Canvas {
                            id: gridCanvas
                            anchors.fill: parent
                            opacity: Theme.currentTheme === "white" ? 0.65 : 0.25
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = Theme.canvasGrid
                                ctx.lineWidth = 1
                                var step = 28
                                for (var x = step; x < width; x += step) {
                                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                                }
                                for (var y = step; y < height; y += step) {
                                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                                }
                            }
                            Connections {
                                target: Theme
                                function onCurrentThemeChanged() { gridCanvas.requestPaint() }
                            }
                        }

                        property real scaleFactor: {
                            if (!root.monitors || root.monitors.length === 0) return 0.12 * root.userZoom
                            var minX = 0, minY = 0, maxX = 1920, maxY = 1080
                            for (var i = 0; i < root.monitors.length; ++i) {
                                var m = root.monitors[i]
                                if (i === 0 || m.x < minX) minX = m.x
                                if (i === 0 || m.y < minY) minY = m.y
                                if (i === 0 || m.x + (m.resW || 1920) > maxX) maxX = m.x + (m.resW || 1920)
                                if (i === 0 || m.y + (m.resH || 1080) > maxY) maxY = m.y + (m.resH || 1080)
                            }
                            var totalW = Math.max(maxX - minX, 1000)
                            var totalH = Math.max(maxY - minY, 800)
                            var padX = 80
                            var padY = 60
                            var sx = (canvas.width - padX * 2) / totalW
                            var sy = (canvas.height - padY * 2) / totalH
                            var computed = Math.min(sx, sy) * root.userZoom
                            return Math.max(computed, 0.08)
                        }

                        property real offX: {
                            if (!root.monitors || root.monitors.length === 0) return 0
                            var minX = 0, maxX = 1920
                            for (var i = 0; i < root.monitors.length; ++i) {
                                var m = root.monitors[i]
                                if (i === 0 || m.x < minX) minX = m.x
                                if (i === 0 || m.x + (m.resW || 1920) > maxX) maxX = m.x + (m.resW || 1920)
                            }
                            var totalW = (maxX - minX) * scaleFactor
                            return (canvas.width - totalW) / 2 - minX * scaleFactor
                        }

                        property real offY: {
                            if (!root.monitors || root.monitors.length === 0) return 0
                            var minY = 0, maxY = 1080
                            for (var i = 0; i < root.monitors.length; ++i) {
                                var m = root.monitors[i]
                                if (i === 0 || m.y < minY) minY = m.y
                                if (i === 0 || m.y + (m.resH || 1080) > maxY) maxY = m.y + (m.resH || 1080)
                            }
                            var totalH = (maxY - minY) * scaleFactor
                            return (canvas.height - totalH) / 2 - minY * scaleFactor
                        }

                        // ── Magnetic Sticking / Proximity Snapping ───
                        property bool hasSnapX: false
                        property bool hasSnapY: false
                        property real guideX: 0
                        property real guideY: 0
                        property string snapLabel: ""

                        function calculateSnap(curIndex, rawX, rawY) {
                            var curMon = root.monitors[curIndex]
                            if (!curMon) return { finalX: rawX, finalY: rawY, hasSnapX: false, hasSnapY: false, guideX: 0, guideY: 0, label: "" }

                            var curW = curMon.resW || 1920
                            var curH = curMon.resH || 1080
                            var threshold = 95 // magnetic snap range in virtual pixels

                            var bestX = rawX
                            var minDiffX = threshold + 1
                            var snapX = false
                            var gx = 0
                            var lx = ""

                            var bestY = rawY
                            var minDiffY = threshold + 1
                            var snapY = false
                            var gy = 0
                            var ly = ""

                            // Snap to origin (0, 0)
                            if (Math.abs(rawX) < minDiffX) {
                                minDiffX = Math.abs(rawX)
                                bestX = 0
                                snapX = true
                                gx = 0
                                lx = "Origin X"
                            }
                            if (Math.abs(rawY) < minDiffY) {
                                minDiffY = Math.abs(rawY)
                                bestY = 0
                                snapY = true
                                gy = 0
                                ly = "Origin Y"
                            }

                            // Snap against other monitors
                            for (var i = 0; i < root.monitors.length; i++) {
                                if (i === curIndex) continue
                                var o = root.monitors[i]
                                var oX = o.x || 0
                                var oY = o.y || 0
                                var oW = o.resW || 1920
                                var oH = o.resH || 1080

                                // 1. Flush Right Edge of other (Adjacent Right)
                                var dAdjR = Math.abs(rawX - (oX + oW))
                                if (dAdjR < minDiffX) {
                                    minDiffX = dAdjR
                                    bestX = oX + oW
                                    snapX = true
                                    gx = oX + oW
                                    lx = "Flush Right of " + o.name
                                }

                                // 2. Flush Left Edge of other (Adjacent Left)
                                var dAdjL = Math.abs(rawX - (oX - curW))
                                if (dAdjL < minDiffX) {
                                    minDiffX = dAdjL
                                    bestX = oX - curW
                                    snapX = true
                                    gx = oX
                                    lx = "Flush Left of " + o.name
                                }

                                // 3. Aligned Top Y
                                var dTop = Math.abs(rawY - oY)
                                if (dTop < minDiffY) {
                                    minDiffY = dTop
                                    bestY = oY
                                    snapY = true
                                    gy = oY
                                    ly = "Top Aligned with " + o.name
                                }

                                // 4. Aligned Bottom Y
                                var dBottom = Math.abs(rawY - (oY + oH - curH))
                                if (dBottom < minDiffY) {
                                    minDiffY = dBottom
                                    bestY = oY + oH - curH
                                    snapY = true
                                    gy = oY + oH
                                    ly = "Bottom Aligned with " + o.name
                                }

                                // 5. Adjacent Under (Top of current touches Bottom of other)
                                var dAdjB = Math.abs(rawY - (oY + oH))
                                if (dAdjB < minDiffY) {
                                    minDiffY = dAdjB
                                    bestY = oY + oH
                                    snapY = true
                                    gy = oY + oH
                                    ly = "Under " + o.name
                                }

                                // 6. Adjacent Above (Bottom of current touches Top of other)
                                var dAdjT = Math.abs(rawY - (oY - curH))
                                if (dAdjT < minDiffY) {
                                    minDiffY = dAdjT
                                    bestY = oY - curH
                                    snapY = true
                                    gy = oY
                                    ly = "Above " + o.name
                                }
                            }

                            var finalX = snapX ? bestX : Math.round(rawX / 10) * 10
                            var finalY = snapY ? bestY : Math.round(rawY / 10) * 10

                            var lbl = ""
                            if (snapX && snapY) lbl = lx + " • " + ly
                            else if (snapX) lbl = lx
                            else if (snapY) lbl = ly

                            return {
                                finalX: finalX,
                                finalY: finalY,
                                hasSnapX: snapX,
                                hasSnapY: snapY,
                                guideX: gx,
                                guideY: gy,
                                label: lbl
                            }
                        }

                        // Guide Line V
                        Rectangle {
                            visible: canvas.hasSnapX
                            width: 1
                            color: Theme.guideColor
                            opacity: 0.9
                            z: 20
                            x: Math.round(canvas.guideX * canvas.scaleFactor + canvas.offX)
                            y: 0
                            height: canvas.height
                        }

                        // Guide Line H
                        Rectangle {
                            visible: canvas.hasSnapY
                            height: 1
                            color: Theme.guideColor
                            opacity: 0.9
                            z: 20
                            y: Math.round(canvas.guideY * canvas.scaleFactor + canvas.offY)
                            x: 0
                            width: canvas.width
                        }

                        // Live Snap Pill Badge
                        Rectangle {
                            visible: (canvas.hasSnapX || canvas.hasSnapY) && canvas.snapLabel !== ""
                            z: 25
                            anchors.top: canvas.top
                            anchors.horizontalCenter: canvas.horizontalCenter
                            anchors.topMargin: 12
                            height: 26
                            width: snapRow.implicitWidth + 24
                            radius: 13
                            color: Theme.surface2
                            border.color: Theme.guideColor
                            border.width: 1

                            RowLayout {
                                id: snapRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰆤"; font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.guideColor }
                                Text { text: canvas.snapLabel; color: Theme.text; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true }
                            }
                        }

                        // ── Monitor Cards on Canvas ────────────────────
                        Repeater {
                            model: root.monitors

                            Item {
                                id: mItem
                                property bool isSelected: index === root.selectedIndex
                                property real screenW: Math.max((modelData.resW || 1920) * canvas.scaleFactor, 180)
                                property real screenH: Math.max((modelData.resH || 1080) * canvas.scaleFactor, 105)

                                width: screenW
                                height: screenH
                                x: (modelData.x || 0) * canvas.scaleFactor + canvas.offX
                                y: (modelData.y || 0) * canvas.scaleFactor + canvas.offY
                                z: mItemMa.drag.active ? 30 : (isSelected ? 10 : 2)

                                property int liveX: modelData.x || 0
                                property int liveY: modelData.y || 0

                                // Flat pitch-black screen with crisp border
                                Rectangle {
                                    id: screenBezel
                                    anchors.fill: parent
                                    radius: 6
                                    color: "#0a0a0a"
                                    border.color: mItem.isSelected ? Theme.accent : (mItemMa.containsMouse ? Theme.borderHi : Theme.border)
                                    border.width: mItem.isSelected ? 2 : 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        RowLayout {
                                            Layout.alignment: Qt.AlignHCenter
                                            spacing: 6
                                            Rectangle {
                                                width: 7; height: 7; radius: 3.5
                                                color: modelData.isLive ? "#27c93f" : Theme.textMuted
                                            }
                                            Text {
                                                text: modelData.name
                                                color: "#ffffff"
                                                font.family: Theme.fontUI
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.resW + "×" + modelData.resH + (modelData.rate ? (" • " + Math.round(modelData.rate) + "Hz") : "")
                                            color: "#9ca3af"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "Pos: " + mItem.liveX + ", " + mItem.liveY
                                            color: mItemMa.drag.active ? "#38bdf8" : "#6b7280"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            font.bold: mItemMa.drag.active
                                        }
                                    }
                                }

                                // Selection Index Badge
                                Rectangle {
                                    anchors.top: screenBezel.top
                                    anchors.right: screenBezel.right
                                    anchors.margins: 6
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: mItem.isSelected ? Theme.accent : Theme.surface2
                                    border.color: mItem.isSelected ? Theme.accent : Theme.border
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: (index + 1)
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: mItem.isSelected ? Theme.crust : Theme.subtext0
                                    }
                                }

                                MouseArea {
                                    id: mItemMa
                                    anchors.fill: screenBezel
                                    hoverEnabled: true
                                    cursorShape: Qt.SizeAllCursor
                                    preventStealing: true
                                    drag.target: mItem
                                    drag.axis: Drag.XAndYAxis

                                    onPressed: root.selectedIndex = index

                                    onPositionChanged: {
                                        if (drag.active) {
                                            var rawX = (mItem.x - canvas.offX) / canvas.scaleFactor
                                            var rawY = (mItem.y - canvas.offY) / canvas.scaleFactor
                                            var snap = canvas.calculateSnap(index, rawX, rawY)

                                            mItem.liveX = Math.round(snap.finalX)
                                            mItem.liveY = Math.round(snap.finalY)

                                            canvas.hasSnapX = snap.hasSnapX
                                            canvas.hasSnapY = snap.hasSnapY
                                            canvas.guideX = snap.guideX
                                            canvas.guideY = snap.guideY
                                            canvas.snapLabel = snap.label

                                            // Magnetic STICK: snap position live while in threshold
                                            if (snap.hasSnapX) {
                                                mItem.x = snap.finalX * canvas.scaleFactor + canvas.offX
                                            }
                                            if (snap.hasSnapY) {
                                                mItem.y = snap.finalY * canvas.scaleFactor + canvas.offY
                                            }
                                        }
                                    }

                                    onReleased: {
                                        var finalX = mItem.liveX
                                        var finalY = mItem.liveY

                                        canvas.hasSnapX = false
                                        canvas.hasSnapY = false
                                        canvas.snapLabel = ""

                                        root.updateMonitor(index, { x: finalX, y: finalY })
                                        root.applyMonitorToHypr(root.monitors[index])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Resolution, Scale & Rate Details Card ──────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: settingsCol.implicitHeight + 36
                radius: Theme.radiusLg
                color: Theme.surface0
                border.color: Theme.border
                border.width: 1
                visible: root.selected !== null

                ColumnLayout {
                    id: settingsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: (root.selected ? root.selected.name : "") + " Settings"
                            color: Theme.text
                            font.family: Theme.fontUI
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        StyledButton {
                            variant: "solid"
                            text: "Apply to Hyprland"
                            iconText: "󰄬"
                            onClicked: {
                                if (root.selected) {
                                    root.applyMonitorToHypr(root.selected)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Resolution Dropdown
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: "Resolution"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: 11; font.weight: 600 }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: Theme.surface1
                                border.color: Theme.border; border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: root.selected ? (root.selected.resW + " × " + root.selected.resH) : ""
                                    color: Theme.text
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: resMenu.open()
                                }

                                Menu {
                                    id: resMenu
                                    background: Rectangle {
                                        implicitWidth: 220
                                        color: Theme.surface1
                                        border.color: Theme.borderHi
                                        border.width: 1
                                        radius: Theme.radiusMd
                                    }
                                    Repeater {
                                        model: root.selected ? root.modesFor(root.selected) : []
                                        MenuItem {
                                            text: modelData.w + "×" + modelData.h
                                            onTriggered: {
                                                var bestRate = modelData.rates.length ? modelData.rates[0] : root.selected.rate
                                                root.updateMonitor(root.selectedIndex, { resW: modelData.w, resH: modelData.h, rate: bestRate })
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Scale Field
                        ColumnLayout {
                            Layout.preferredWidth: 120
                            spacing: 4
                            Text { text: "Scale"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: 11; font.weight: 600 }
                            StyledTextField {
                                Layout.fillWidth: true
                                text: root.selected ? String(root.selected.scale) : "1"
                                onEditingFinished: {
                                    var v = parseFloat(text)
                                    if (!isNaN(v) && v > 0) root.updateMonitor(root.selectedIndex, { scale: v })
                                }
                            }
                        }

                        // Transform Field
                        ColumnLayout {
                            Layout.preferredWidth: 120
                            spacing: 4
                            Text { text: "Transform"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: 11; font.weight: 600 }
                            StyledTextField {
                                Layout.fillWidth: true
                                text: root.selected ? String(root.selected.transform || 0) : "0"
                                onEditingFinished: {
                                    var v = parseInt(text)
                                    if (!isNaN(v)) root.updateMonitor(root.selectedIndex, { transform: v })
                                }
                            }
                        }
                    }

                    // Refresh Rate Chips
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text { text: "Refresh Rate"; color: Theme.textMuted; font.family: Theme.fontUI; font.pixelSize: 11; font.weight: 600 }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8
                            Repeater {
                                model: root.selected ? root.ratesFor(root.selected, root.selected.resW, root.selected.resH) : []
                                Rectangle {
                                    readonly property real thisRate: modelData
                                    readonly property bool isActive: root.selected && Math.round(root.selected.rate) === Math.round(thisRate)
                                    width: rateLabel.implicitWidth + 24
                                    height: 32
                                    radius: Theme.radiusSm
                                    color: isActive ? Theme.accent : Theme.surface1
                                    border.color: isActive ? Theme.accent : Theme.border
                                    border.width: 1

                                    Text {
                                        id: rateLabel
                                        anchors.centerIn: parent
                                        text: (Math.round(thisRate * 100) / 100) + " Hz"
                                        color: isActive ? Theme.crust : Theme.text
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: isActive
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.updateMonitor(root.selectedIndex, { rate: thisRate })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
