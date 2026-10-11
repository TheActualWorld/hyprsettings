pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string user:   Quickshell.env("USER") || "user"
    property string host:   ""
    property string distro: ""
    property string kernel: ""
    property string cpu:    ""
    property string gpu:    ""
    property string de:     ""
    property string avatar: ""

    Process {
        id: p
        command: ["bash", "-c",
            "u=$(whoami 2>/dev/null || echo \"$USER\"); " +
            "h=$(hostnamectl --static 2>/dev/null || hostname); " +
            "distro=$(. /etc/os-release 2>/dev/null; echo \"${NAME:-Linux}\"); " +
            "kern=$(uname -r); " +
            "cpu=$(grep -m1 \x27model name\x27 /proc/cpuinfo 2>/dev/null | sed -e \x27s/.*: //\x27 -e \x27s/(R)//g\x27 -e \x27s/(TM)//g\x27 -e \x27s/  */ /g\x27); " +
            "gpu=$(lspci 2>/dev/null | grep -Ei \x27vga|3d|display\x27 | head -1 | sed -e \x27s/.*: //\x27 -e \x27s/Corporation //\x27 -e \x27s/ (rev.*)//\x27); " +
            "de=\"\"; " +
            "if [ -n \"$XDG_CURRENT_DESKTOP\" ]; then de=\"$XDG_CURRENT_DESKTOP\"; fi; " +
            "if [ -z \"$de\" ] && [ -n \"$DESKTOP_SESSION\" ]; then de=\"$DESKTOP_SESSION\"; fi; " +
            "if [ -z \"$de\" ]; then " +
            "    if pgrep -x Hyprland >/dev/null 2>&1; then de=\"Hyprland\"; " +
            "    elif pgrep -x sway >/dev/null 2>&1; then de=\"Sway\"; " +
            "    elif pgrep -x niri >/dev/null 2>&1; then de=\"Niri\"; " +
            "    elif pgrep -x kwin_wayland >/dev/null 2>&1; then de=\"KDE Plasma\"; " +
            "    elif pgrep -x gnome-shell >/dev/null 2>&1; then de=\"GNOME\"; " +
            "    elif pgrep -x wayfire >/dev/null 2>&1; then de=\"Wayfire\"; " +
            "    elif pgrep -x river >/dev/null 2>&1; then de=\"River\"; fi; " +
            "fi; " +
            "avatar=\"\"; " +
            "for f in \"$HOME/.face\" \"$HOME/.face.icon\" \"/var/lib/AccountsService/icons/$u\"; do " +
            "    if [ -f \"$f\" ]; then avatar=\"$f\"; break; fi; " +
            "done; " +
            "echo USER=$u; " +
            "echo HOST=$h; " +
            "echo DISTRO=$distro; " +
            "echo KERNEL=$kern; " +
            "echo CPU=$cpu; " +
            "echo GPU=$gpu; " +
            "echo DE=${de:-Desktop}; " +
            "echo AVATAR=$avatar"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                for (var i=0; i<lines.length; i++) {
                    var kv = lines[i].split("=");
                    if (kv.length < 2) continue;
                    var k = kv[0]; var v = lines[i].substring(k.length+1);
                    if (k === "USER") root.user = v;
                    else if (k === "HOST") root.host = v;
                    else if (k === "DISTRO") root.distro = v;
                    else if (k === "KERNEL") root.kernel = v;
                    else if (k === "CPU") root.cpu = v;
                    else if (k === "GPU") root.gpu = v;
                    else if (k === "DE") root.de = v;
                    else if (k === "AVATAR") root.avatar = v;
                }
            }
        }
    }
}
