pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var monitors: []          // list from hyprctl (live)
    property var availableModes: ({})  // { "eDP-1": ["1920x1080@144", ...] }
    signal refreshed()

    function refresh() { p.running = false; p.running = true; }

    Process {
        id: p
        command: ["bash", "-c", "hyprctl -j monitors all"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text);
                    root.monitors = arr;
                    var modes = {};
                    for (var i=0;i<arr.length;i++) {
                        modes[arr[i].name] = arr[i].availableModes || [];
                    }
                    root.availableModes = modes;
                    root.refreshed();
                } catch(e) { console.warn("Monitors parse err", e); }
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; onTriggered: root.refresh() }
}
