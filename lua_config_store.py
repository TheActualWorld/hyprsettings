#!/usr/bin/env python3
import sys
import os
import re
import json
import base64
import subprocess

HYPR_DIR = os.path.expanduser("~/.config/hypr")
CONF_DIR = os.path.join(HYPR_DIR, "config")

def normalize_mods(mods):
    tokens = [t.strip() for t in mods.replace(",", " ").replace("+", " ").split() if t.strip()]
    norm = []
    for t in tokens:
        if t in ["$mainMod", "SUPER", "Super", "Mod4"]:
            if "$mainMod" not in norm:
                norm.append("$mainMod")
        elif t.upper() in ["SHIFT", "SHIFT_L", "SHIFT_R", "SHIFTL", "SHIFTR"]:
            if "SHIFT" not in norm:
                norm.append("SHIFT")
        elif t.upper() in ["CTRL", "CONTROL", "CONTROL_L", "CONTROL_R"]:
            if "CTRL" not in norm:
                norm.append("CTRL")
        elif t.upper() in ["ALT", "ALT_L", "ALT_R", "MOD1"]:
            if "ALT" not in norm:
                norm.append("ALT")
        else:
            norm.append(t)
    return " ".join(norm)

def read_lua_configs():
    data = {
        "language": "us",
        "kbOptions": "grp:alt_shift_toggle",
        "wallpaperDir": os.path.expanduser("~/wallpapers"),
        "openGuideAtStartup": False,
        "topbarHelpIcon": True,
        "workspaceCount": 9,
        "uiScale": 1.2,
        "theme": "black",

        "monitors": [],
        "startup": [],
        "keybinds": [],
        "hardwareEnvs": []
    }

    # 1. Read settings.lua
    settings_path = os.path.join(CONF_DIR, "settings.lua")
    if os.path.isfile(settings_path):
        with open(settings_path, "r") as f:
            content = f.read()
        m_lang = re.search(r'kb_layout\s*=\s*"([^"]+)"', content)
        if m_lang:
            data["language"] = m_lang.group(1)
        m_opt = re.search(r'kb_options\s*=\s*"([^"]+)"', content)
        if m_opt:
            data["kbOptions"] = m_opt.group(1)

    # 2. Read env.lua
    env_path = os.path.join(CONF_DIR, "env.lua")
    if os.path.isfile(env_path):
        with open(env_path, "r") as f:
            for line in f:
                line = line.strip()
                m_wp = re.search(r'hl\.env\("WALLPAPER_DIR",\s*"([^"]+)"\)', line)
                if m_wp:
                    data["wallpaperDir"] = m_wp.group(1)
                m_env = re.search(r'hl\.env\("([^"]+)",\s*"([^"]*)"\)', line)
                if m_env and m_env.group(1) not in ["XDG_PICTURES_DIR", "XDG_VIDEOS_DIR", "WALLPAPER_DIR", "HYPR_SCRIPTS"]:
                    data["hardwareEnvs"].append(f'env = {m_env.group(1)},{m_env.group(2)}')

    # 3. Read monitors.lua
    monitors_path = os.path.join(CONF_DIR, "monitors.lua")
    if os.path.isfile(monitors_path):
        with open(monitors_path, "r") as f:
            content = f.read()
        blocks = re.findall(r'hl\.monitor\(\{([^}]+)\}\)', content)
        for b in blocks:
            m_out = re.search(r'output\s*=\s*"([^"]+)"', b)
            m_mode = re.search(r'mode\s*=\s*"([^"]+)"', b)
            m_pos = re.search(r'position\s*=\s*"([^"]+)"', b)
            m_scale = re.search(r'scale\s*=\s*([0-9.]+)', b)
            m_trans = re.search(r'transform\s*=\s*([0-9]+)', b)

            if m_out and m_mode and m_pos:
                out_name = m_out.group(1)
                mode_str = m_mode.group(1)
                pos_str = m_pos.group(1)
                scale_val = float(m_scale.group(1)) if m_scale else 1.0
                trans_val = int(m_trans.group(1)) if m_trans else 0

                res_w, res_h, rate = 1920, 1080, 60.0
                if "@" in mode_str:
                    res_part, rate_part = mode_str.split("@", 1)
                    if "x" in res_part:
                        res_w, res_h = [int(x) for x in res_part.split("x", 1)]
                    try:
                        rate = float(rate_part)
                    except ValueError:
                        rate = 60.0
                
                x, y = 0, 0
                if "x" in pos_str:
                    try:
                        x, y = [int(p) for p in pos_str.split("x", 1)]
                    except ValueError:
                        x, y = 0, 0

                data["monitors"].append({
                    "name": out_name,
                    "resW": res_w,
                    "resH": res_h,
                    "rate": rate,
                    "x": x,
                    "y": y,
                    "scale": scale_val,
                    "transform": trans_val,
                    "enabled": True
                })

    # 4. Read autostart.lua
    autostart_path = os.path.join(CONF_DIR, "autostart.lua")
    if os.path.isfile(autostart_path):
        with open(autostart_path, "r") as f:
            for line in f:
                line = line.strip()
                m_exec = re.search(r'hl\.exec_cmd\("(.+)"\)', line)
                if m_exec:
                    cmd_val = m_exec.group(1).replace('\\"', '"').replace('\\\\', '\\')
                    if "toggle guide" in cmd_val:
                        data["openGuideAtStartup"] = True
                    else:
                        data["startup"].append({
                            "command": cmd_val,
                            "isEditing": False
                        })

    # 5. Read keybindings.lua
    keybinds_path = os.path.join(CONF_DIR, "keybindings.lua")
    if os.path.isfile(keybinds_path):
        with open(keybinds_path, "r") as f:
            for line in f:
                line = line.strip()
                if not line.startswith("hl.bind"):
                    continue
                m_bind = re.match(r'hl\.bind\((.+?),\s*(hl\.dsp\..+?|function\(\).+?end)(?:,\s*\{([^}]+)\})?\)$', line)
                if m_bind:
                    key_expr = m_bind.group(1).strip()
                    dsp_expr = m_bind.group(2).strip()
                    opts_expr = m_bind.group(3) or ""

                    b_type = "bind"
                    is_rep = "repeat" in opts_expr or "repeating" in opts_expr
                    is_lck = "locked" in opts_expr
                    if is_rep and is_lck:
                        b_type = "bindel"
                    elif is_rep:
                        b_type = "binde"
                    elif is_lck:
                        b_type = "bindl"
                    elif "release" in opts_expr:
                        b_type = "bindr"
                    elif ("drag()" in dsp_expr or "resize()" in dsp_expr) and "mouse:" in key_expr:
                        b_type = "bindm"

                    raw_key = key_expr.replace('mainMod .. "', '$mainMod').replace('"', '').strip()
                    tokens = [t.strip() for t in raw_key.split("+") if t.strip()]
                    key_name = tokens[-1] if tokens else ""
                    raw_mods = " ".join(tokens[:-1]) if len(tokens) > 1 else ""
                    mods_str = normalize_mods(raw_mods)

                    dispatcher = "exec"
                    command = ""

                    m_exec = re.search(r'hl\.dsp\.exec_cmd\("(.+)"\)', dsp_expr)
                    if m_exec:
                        dispatcher = "exec"
                        command = m_exec.group(1).replace('\\"', '"').replace('\\\\', '\\')
                    elif "close()" in dsp_expr:
                        dispatcher = "killactive"
                    elif "fullscreen()" in dsp_expr:
                        dispatcher = "fullscreen"
                    elif "pseudo()" in dsp_expr:
                        dispatcher = "pseudo"
                    elif "toggle_special" in dsp_expr:
                        dispatcher = "togglespecialworkspace"
                    elif "drag()" in dsp_expr:
                        dispatcher = "movewindow"
                    elif "hl.dsp.window.resize()" in dsp_expr:
                        dispatcher = "resizewindow"
                    elif "exit(" in dsp_expr:
                        dispatcher = "exit"
                    elif 'hl.dsp.focus' in dsp_expr:
                        m_ws = re.search(r'workspace\s*=\s*"?([a-zA-Z0-9_+ -]+)"?', dsp_expr)
                        m_dir = re.search(r'direction\s*=\s*"([^"]+)"', dsp_expr)
                        if m_ws:
                            dispatcher = "workspace"
                            command = str(m_ws.group(1))
                        elif m_dir:
                            dispatcher = "movefocus"
                            command = m_dir.group(1)
                    elif 'hl.dsp.window.move' in dsp_expr:
                        m_ws = re.search(r'workspace\s*=\s*"?([a-zA-Z0-9_:]+)"?', dsp_expr)
                        m_dir = re.search(r'direction\s*=\s*"([^"]+)"', dsp_expr)
                        if m_ws:
                            dispatcher = "movetoworkspace"
                            command = str(m_ws.group(1))
                        elif m_dir:
                            dispatcher = "movewindow"
                            command = m_dir.group(1)
                    elif 'hl.dsp.window.resize' in dsp_expr:
                        dispatcher = "resizeactive"
                        m_x = re.search(r'x\s*=\s*(-?\d+)', dsp_expr)
                        m_y = re.search(r'y\s*=\s*(-?\d+)', dsp_expr)
                        if m_x and m_y:
                            command = f"{m_x.group(1)} {m_y.group(1)}"

                    data["keybinds"].append({
                        "type": b_type,
                        "mods": mods_str,
                        "key": key_name,
                        "dispatcher": dispatcher,
                        "command": command,
                        "isEditing": False
                    })

    # Ensure workspace 1-9 binds exist
    existing_ws = {b["key"] for b in data["keybinds"] if b.get("dispatcher") == "workspace"}
    existing_mws = {b["key"] for b in data["keybinds"] if b.get("dispatcher") == "movetoworkspace"}
    for i in range(1, 10):
        s_i = str(i)
        if s_i not in existing_ws:
            data["keybinds"].append({
                "type": "bind",
                "mods": "$mainMod",
                "key": s_i,
                "dispatcher": "workspace",
                "command": s_i,
                "isEditing": False
            })
        if s_i not in existing_mws:
            data["keybinds"].append({
                "type": "bind",
                "mods": "$mainMod SHIFT",
                "key": s_i,
                "dispatcher": "movetoworkspace",
                "command": s_i,
                "isEditing": False
            })

    ui_json_path = os.path.join(CONF_DIR, "ui_settings.json")
    if os.path.isfile(ui_json_path):
        try:
            with open(ui_json_path, "r") as f:
                ui_data = json.load(f)
                data.update(ui_data)
        except Exception:
            pass

    return data

def write_lua_configs(data):
    # Save UI state (theme, etc.)
    try:
        ui_json_path = os.path.join(CONF_DIR, "ui_settings.json")
        ui_data = {}
        if os.path.isfile(ui_json_path):
            with open(ui_json_path, "r") as f:
                ui_data = json.load(f)
        ui_data["theme"] = data.get("theme", "black")
        with open(ui_json_path, "w") as f:
            json.dump(ui_data, f, indent=2)
    except Exception as e:
        pass

    os.makedirs(CONF_DIR, exist_ok=True)

    # 1. settings.lua
    kb_layout = data.get("language", "us")
    kb_options = data.get("kbOptions", "grp:alt_shift_toggle")
    settings_lua = f"""-- Input and Keyboard configuration
-- Generated directly from Quickshell Settings

hl.config({{
    input = {{
        kb_layout = "{kb_layout}",
        kb_options = "{kb_options}",
        follow_mouse = 1,
        mouse_refocus = false,
        float_switch_override_focus = 0,
        repeat_rate = 50,
        repeat_delay = 500,
        touchpad = {{
            natural_scroll = true
        }}
    }}
}})
"""
    with open(os.path.join(CONF_DIR, "settings.lua"), "w") as f:
        f.write(settings_lua)

    # 2. monitors.lua
    monitors = data.get("monitors", [])
    monitors_out = [
        "-- Monitors and Workspaces configuration",
        "-- Generated directly from Quickshell Settings\n"
    ]
    if monitors:
        for m in monitors:
            name = m.get("name", "")
            res_w = m.get("resW", 1920)
            res_h = m.get("resH", 1080)
            rate = m.get("rate", 60)
            x = m.get("x", 0)
            y = m.get("y", 0)
            scale = m.get("scale", 1.0)
            try:
                scale_val = float(scale)
            except ValueError:
                scale_val = 1.0
            transform = m.get("transform", 0)

            mon_entry = [
                f'    output = "{name}",',
                f'    mode = "{res_w}x{res_h}@{rate}",',
                f'    position = "{x}x{y}",',
                f'    scale = {scale_val}'
            ]
            if transform and transform != 0:
                mon_entry.append(f'    transform = {transform}')

            monitors_out.append("hl.monitor({")
            monitors_out.append("\n".join(mon_entry))
            monitors_out.append("})\n")
    else:
        monitors_out.append('hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })\n')

    monitors_out.append('hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })')
    monitors_out.append('hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1" })')
    monitors_out.append('hl.workspace_rule({ workspace = "3", monitor = "DP-1" })\n')

    with open(os.path.join(CONF_DIR, "monitors.lua"), "w") as f:
        f.write("\n".join(monitors_out))

    # 3. autostart.lua
    startup = data.get("startup", [])
    open_guide = data.get("openGuideAtStartup", False)
    autostart_out = [
        "-- Autostart programs on Hyprland startup",
        "-- Generated directly from Quickshell Settings\n",
        'hl.on("hyprland.start", function()'
    ]
    for s in startup:
        cmd = s.get("command", "").strip() if isinstance(s, dict) else str(s).strip()
        if not cmd or cmd.startswith("#") or "settings_watcher.sh" in cmd:
            continue
        cmd_escaped = cmd.replace("\\", "\\\\").replace('"', '\\"')
        autostart_out.append(f'    hl.exec_cmd("{cmd_escaped}")')

    if open_guide:
        autostart_out.append(f'    hl.exec_cmd("bash -c \'sleep 1 && {HYPR_DIR}/scripts/qs_manager.sh toggle guide\'")')

    autostart_out.append("end)\n")
    with open(os.path.join(CONF_DIR, "autostart.lua"), "w") as f:
        f.write("\n".join(autostart_out))

    # 4. keybindings.lua
    keybinds = data.get("keybinds", [])
    kb_out = [
        "-- Keybindings configuration",
        "-- Generated directly from Quickshell Settings\n",
        'local mainMod = "SUPER"\n'
    ]

    def format_bind(b_type, mods, key, dispatcher, command):
        key_clean = key.strip()
        normalized_mods = normalize_mods(mods) if mods else ""

        if normalized_mods:
            if "$mainMod" in normalized_mods:
                extra_mods = [t.strip() for t in normalized_mods.replace("$mainMod", "").split() if t.strip() and t.strip() != "+"]
                if extra_mods:
                    extras = " + ".join(extra_mods)
                    lhs_expr = f'mainMod .. " + {extras} + {key_clean}"'
                else:
                    lhs_expr = f'mainMod .. " + {key_clean}"'
            else:
                mod_tokens = [t.strip() for t in normalized_mods.replace(",", " ").split() if t.strip() and t.strip() != "+"]
                all_tokens = mod_tokens + [key_clean]
                lhs_expr = f'"{ " + ".join(all_tokens) }"'
        else:
            lhs_expr = f'"{key_clean}"'

        cmd = command.strip() if command else ""
        cmd = cmd.replace(os.path.expanduser("~/.config/hypr/"), "~/.config/hypr/")

        if dispatcher == "exec":
            cmd_esc = cmd.replace("\\", "\\\\").replace('"', '\\"')
            dsp_expr = f'hl.dsp.exec_cmd("{cmd_esc}")'
        elif dispatcher == "killactive":
            dsp_expr = "hl.dsp.window.close()"
        elif dispatcher == "fullscreen":
            dsp_expr = "hl.dsp.window.fullscreen()"
        elif dispatcher in ["togglefloating", "float"]:
            dsp_expr = "hl.dsp.window.float()"
        elif dispatcher in ["pseudo", "Pseudo"]:
            dsp_expr = "hl.dsp.window.pseudo()"
        elif dispatcher == "togglespecialworkspace":
            dsp_expr = "hl.dsp.workspace.toggle_special()"
        elif dispatcher == "movefocus":
            dsp_expr = f'hl.dsp.focus({{ direction = "{cmd}" }})'
        elif dispatcher == "movewindow" and b_type == "bindm":
            dsp_expr = "hl.dsp.window.drag()"
        elif dispatcher == "movewindow":
            dsp_expr = f'hl.dsp.window.move({{ direction = "{cmd}" }})'
        elif dispatcher == "resizewindow" and b_type == "bindm":
            dsp_expr = "hl.dsp.window.resize()"
        elif dispatcher == "movetoworkspace":
            if cmd.isdigit():
                dsp_expr = f'hl.dsp.window.move({{ workspace = {cmd} }})'
            else:
                dsp_expr = f'hl.dsp.window.move({{ workspace = "{cmd}" }})'
        elif dispatcher == "workspace":
            if cmd.isdigit():
                dsp_expr = f'hl.dsp.focus({{ workspace = {cmd} }})'
            else:
                dsp_expr = f'hl.dsp.focus({{ workspace = "{cmd}" }})'
        elif dispatcher == "resizeactive":
            coords = [int(c) for c in cmd.split() if c.lstrip("-").isdigit()]
            if len(coords) >= 2:
                dsp_expr = f'hl.dsp.window.resize({{ x = {coords[0]}, y = {coords[1]}, relative = true }})'
            else:
                dsp_expr = f'hl.dsp.exec_cmd("hyprctl dispatch resizeactive {cmd}")'
        else:
            cmd_esc = cmd.replace("\\", "\\\\").replace('"', '\\"')
            if cmd_esc:
                dsp_expr = f'hl.dsp.exec_cmd("hyprctl dispatch {dispatcher} {cmd_esc}")'
            else:
                dsp_expr = f'hl.dsp.exec_cmd("hyprctl dispatch {dispatcher}")'

        opts = []
        if b_type in ("binde", "bindel"):
            opts.append("repeating = true")
        if b_type in ("bindl", "bindel"):
            opts.append("locked = true")
        elif b_type == "bindr":
            opts.append("release = true")

        if opts:
            return f'hl.bind({lhs_expr}, {dsp_expr}, {{ {", ".join(opts)} }})'
        else:
            return f'hl.bind({lhs_expr}, {dsp_expr})'

    seen_binds = set()
    if keybinds:
        for b in keybinds:
            b_type = b.get("type", "bind")
            mods = b.get("mods", "")
            key = b.get("key", "")
            dispatcher = b.get("dispatcher", "exec")
            command = b.get("command", "")
            
            dedup_key = (b_type, normalize_mods(mods), key)
            if dedup_key in seen_binds:
                continue
            seen_binds.add(dedup_key)
            
            kb_out.append(format_bind(b_type, mods, key, dispatcher, command))
    else:
        kb_out.append('hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))')
        kb_out.append('hl.bind(mainMod .. " + Q", hl.dsp.window.close())')

    with open(os.path.join(CONF_DIR, "keybindings.lua"), "w") as f:
        f.write("\n".join(kb_out) + "\n")

    # 5. env.lua
    wp_dir = data.get("wallpaperDir", os.path.expanduser("~/wallpapers"))
    pic_dir = os.path.expanduser("~/Pictures")
    vid_dir = os.path.expanduser("~/Videos")
    hw_envs = data.get("hardwareEnvs", [])

    env_out = [
        "-- Environment Variables configuration",
        "-- Generated directly from Quickshell Settings\n",
        f'hl.env("XDG_PICTURES_DIR", "{pic_dir}")',
        f'hl.env("XDG_VIDEOS_DIR", "{vid_dir}")',
        f'hl.env("WALLPAPER_DIR", "{wp_dir}")',
        f'hl.env("HYPR_SCRIPTS", "{HYPR_DIR}/scripts")'
    ]
    for item in hw_envs:
        if "env =" in item:
            clean = item.split("env =", 1)[1].strip()
            if "," in clean:
                k, v = [x.strip() for x in clean.split(",", 1)]
                env_out.append(f'hl.env("{k}", "{v}")')

    with open(os.path.join(CONF_DIR, "env.lua"), "w") as f:
        f.write("\n".join(env_out) + "\n")

    # Reload Hyprland if running
    try:
        subprocess.run(["hyprctl", "dispatch", "submap", "reset"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--read":
        res = read_lua_configs()
        print(json.dumps(res, indent=2))
    elif len(sys.argv) > 2 and sys.argv[1] == "--write":
        raw_b64 = sys.argv[2]
        decoded = base64.b64decode(raw_b64).decode("utf-8")
        payload = json.loads(decoded)
        write_lua_configs(payload)
        print("OK")
    else:
        print("Usage: lua_config_store.py --read | --write <b64_json>")
