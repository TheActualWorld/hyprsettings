pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string hyprLuaDir: homeDir + "/.config/hypr"
    readonly property string bundledScript: Qt.resolvedUrl("../lua_config_store.py").toString().replace(/^file:\/\//, "")
    readonly property string storeScript: {
        var local = Qt.resolvedUrl("../lua_config_store.py").toString().replace(/^file:\/\//, "");
        return local;
    }

    // Live state
    property var data: ({})
    property bool loaded: false
    signal changed()

    // --- Load directly from Lua configs ---
    Process {
        id: loader
        command: ["python3", root.storeScript, "--read"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        root.data = JSON.parse(this.text);
                        root.loaded = true;
                        root.changed();
                    }
                } catch(e) {
                    console.warn("SettingsStore read error:", e);
                }
            }
        }
    }

    function reload() {
        loader.running = false;
        loader.running = true;
    }

    Component.onCompleted: reload()

    // --- Save directly into Lua configs ---
    Process {
        id: saver
        command: ["bash", "-c", "true"]
    }

    function save() {
        var json = JSON.stringify(root.data);
        var b64 = Qt.btoa(json);
        saver.command = ["python3", root.storeScript, "--write", b64];
        saver.running = true;
        root.changed();
    }

    // --- Helpers ---
    function get(key, fallback) {
        return (root.data && root.data.hasOwnProperty(key)) ? root.data[key] : fallback;
    }

    function set(key, value) {
        var d = Object.assign({}, root.data || {});
        d[key] = value;
        root.data = d;
        save();
    }

    // Deep replace an entire array (keybinds, startup, monitors)
    function setArray(key, arr) {
        var d = Object.assign({}, root.data || {});
        d[key] = arr;
        root.data = d;
        save();
    }
}
