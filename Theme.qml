pragma Singleton
import QtQuick
import Quickshell
import "./services"

Singleton {
    id: theme

    property string currentTheme: SettingsStore.get("theme", "black")

    Connections {
        target: SettingsStore
        function onChanged() {
            var t = SettingsStore.get("theme", "black");
            if (t && t !== theme.currentTheme) theme.currentTheme = t;
        }
    }

    readonly property var themes: ({
        "black": {
            name: "Pitch Black",
            bgBase: "#050505", bgSurface: "#0a0a0a", bgCard: "#0e0e0e",
            surface1: "#141414", surface2: "#1c1c1c",
            border: "#1c1c1c", borderHi: "#333333",
            text: "#ffffff", subtext0: "#e4e4e4", subtext1: "#999999", textMuted: "#555555",
            accent: "#ffffff", accentHover: "#e0e0e0", accentSoft: "#161616",
            green: "#27c93f", red: "#ff6e6e",
            canvasBg: "#070707", canvasGrid: "#222222", guideColor: "#ffffff"
        },
        "white": {
            name: "Pure White",
            bgBase: "#f8f9fa", bgSurface: "#f0f2f5", bgCard: "#ffffff",
            surface1: "#f1f3f5", surface2: "#e9ecef",
            border: "#dee2e6", borderHi: "#ced4da",
            text: "#111827", subtext0: "#1f2937", subtext1: "#4b5563", textMuted: "#6b7280",
            accent: "#111827", accentHover: "#374151", accentSoft: "#f3f4f6",
            green: "#16a34a", red: "#dc2626",
            canvasBg: "#f1f3f5", canvasGrid: "#dee2e6", guideColor: "#2563eb"
        }
    })

    readonly property var activeT: themes[currentTheme] || themes["black"]

    readonly property color base:         activeT.bgBase
    readonly property color mantle:       activeT.bgSurface
    readonly property color crust:        (currentTheme === "white" ? "#ffffff" : activeT.bgBase)
    readonly property color surface0:     activeT.bgCard
    readonly property color surface1:     activeT.surface1
    readonly property color surface2:     activeT.surface2
    readonly property color overlay0:     activeT.border
    readonly property color overlay1:     activeT.borderHi

    readonly property color text:         activeT.text
    readonly property color subtext0:     activeT.subtext0
    readonly property color subtext1:     activeT.subtext1
    readonly property color textMuted:    activeT.textMuted
    readonly property color textDisabled: activeT.textMuted

    readonly property color border:       activeT.border
    readonly property color borderHi:     activeT.borderHi
    readonly property color borderDim:    activeT.border

    readonly property color accent:       activeT.accent
    readonly property color accent2:      activeT.accentHover
    readonly property color accentHover:  activeT.accentHover
    readonly property color accentSoft:   activeT.accentSoft
    readonly property color green:        activeT.green
    readonly property color yellow:       activeT.accent
    readonly property color orange:       activeT.accent
    readonly property color red:          activeT.red
    readonly property color cyan:         activeT.accent
    readonly property color pink:         activeT.accent

    // Dedicated Monitor Canvas Colors
    readonly property color canvasBg:     activeT.canvasBg || "#070707"
    readonly property color canvasGrid:   activeT.canvasGrid || "#222222"
    readonly property color guideColor:   activeT.guideColor || activeT.accent

    // Semantic aliases
    readonly property color bg:           base
    readonly property color sidebar:      mantle
    readonly property color surface:      surface0
    readonly property color subtext:      subtext0
    readonly property color muted:        subtext1
    readonly property color danger:       red
    readonly property color success:      green
    readonly property color warning:      yellow

    readonly property color gradA:        activeT.accent
    readonly property color gradB:        activeT.subtext1

    // Fonts
    readonly property string font:        "JetBrainsMono Nerd Font"
    readonly property string fontUI:      "JetBrainsMono Nerd Font"
    readonly property string fontMono:    "JetBrainsMono Nerd Font"
    readonly property string fontIcon:    "JetBrainsMono Nerd Font"
    readonly property string fontBrand:   "JetBrainsMono Nerd Font"

    // Sizes
    readonly property int radiusXl:       14
    readonly property int radiusLg:       10
    readonly property int radiusMd:       8
    readonly property int radiusSm:       6
    readonly property int radiusXs:       4
    readonly property int spacing:        12

    // Timings
    readonly property int animFast:       100
    readonly property int animMed:        180
    readonly property int animSlow:       260
}
