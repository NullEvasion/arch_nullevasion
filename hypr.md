```ini
# #######################################################################################
#                                                                                       #
#   Hyprland                                                                            #
#   Version: 0.57.0                                                                     #
#                                                                                       #
# #######################################################################################
```

# Установка пакетов

```bash
sudo pacman -S \
    hyprland hyprshot kitty waybar \
    wofi mako hyprpolkitagent pipewire wireplumber \
    qt6-wayland xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk
```

`hyprland`: динамический тайлинговый Wayland-композитор
`hyprshot`: утилита для создания скриншотов
`kitty`: быстрый терминал с поддержкой GPU-ускорения
`waybar`: настраиваемая статус-панель сверху или снизу экрана
`wofi`: меню запуска приложений (лаунчер) и поиск
`mako`: легковесный сервер всплывающих уведомлений
`hyprpolkitagent`: агент PolicyKit для запроса прав администратора
`pipewire`: современный движок для работы со звуком и видеопотоками
`wireplumber`: сессионный менеджер для управления звуковыми устройствами в PipeWire
`qt6-wayland`: поддержка нативного запуска современных QT6-приложений в Wayland
`xdg-desktop-portal-hyprland`: интеграция Hyprland с системой (шаринг экрана, открытие файлов)
`xdg-desktop-portal-gtk`: fallback-портал для корректной работы GTK-приложений (темы оформления, диалоговые окна)

---

# Редактирование конфигураций

## Hyprland.lua

```bash
nano ~/.config/hypr/hyprland.lua
```

```lua
-- Hyprland 0.57+ Lua configuration

-- Environment variables (set before the display server initializes)
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GTK_THEME", "Colloid-Dark")

-- Monitor: fallback rule for any monitor without a more specific rule
hl.monitor({
    output = "DP-2",
    mode = "1440x900@59.89",
    position = "auto",
    scale = 1,
})

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 3 && easyeffects --gapplication-service")
    hl.exec_cmd("~/.config/hypr/wallpaper.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- Input
hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle, compose:ralt",
        follow_mouse = 1,
    },
})

-- Keybindings
local mod = "SUPER"

-- Exit / close / launch
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("wofi --show drun --normal-window --style ~/.config/wofi/style.css"))

-- Workspaces 1-6
for i = 1, 6 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

-- Window actions and focus
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + X", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Force-kill active window (SIGKILL)
hl.bind(mod .. " + SHIFT + C", hl.dsp.window.kill())

-- Manual reload (Lua configs also reload automatically when saved)
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Screenshot and clipboard history
hl.bind(mod .. " + Z", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Volume: locked + repeating reproduces the old bindel behavior
hl.bind(mod .. " + A", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
    locked = true,
    repeating = true,
})
hl.bind(mod .. " + D", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), {
    locked = true,
    repeating = true,
})

-- Mouse: move with SUPER + left mouse button, resize with right mouse button
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- General appearance
hl.config({
    general = {
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgb(1793d1)", "rgb(33ccff)" },
                angle = 45,
            },
            inactive_border = "rgba(1793d11a)",
        },
        gaps_in = 5,
        gaps_out = 10,
    },

    decoration = {
        rounding = 12,
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = 0x55000000,
        },

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            noise = 0.008,
            contrast = 1.0,
            brightness = 1.0,
        },
    },
})

-- Animation curve and animations
hl.curve("smooth", {
    type = "bezier",
    points = { { 0.25, 1.0 }, { 0.5, 1.0 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "smooth" })

-- Window rules: 0.95 opacity for all windows; selected apps stay fully opaque.
hl.window_rule({
    match = { class = ".*" },
    opacity = "0.95",
})

local fully_opaque = "1.0 override 1.0 override 1.0 override"

hl.window_rule({ match = { class = "^steam_app_.*$" }, opacity = fully_opaque })
hl.window_rule({ match = { class = "^Minecraft.*$" }, opacity = fully_opaque })
hl.window_rule({ match = { class = "^org-prismlauncher-EntryPoint$" }, opacity = fully_opaque })
hl.window_rule({ match = { class = "^Terraria.*$" }, opacity = fully_opaque })

-- Layer rules: blur only opaque Waybar regions (islands)
hl.layer_rule({
    match = { namespace = "^waybar$" },
    blur = true,
    ignore_alpha = 0.2,
})
```
Параметры `hl.env` для Nvidia нужны такие:

```lua
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GTK_THEME", "Colloid-Dark")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
```

Параметры монитора, для `hl.monitor` можно узнать командой:

```bash
hyprctl monitors
```

## Waybar

Редактируем конфигурацию Waybar:

```bash
nano ~/.config/waybar/config.jsonc
```

```jsonc
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock", "clock#date"],
    "modules-right": ["cpu", "memory", "temperature", "pulseaudio", "network", "hyprland/language", "tray"],

    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{name}",
        "on-click": "activate"
    },

    "clock": {
        "format": "{:%H:%M}",
        "tooltip": false
    },

    "clock#date": {
        "format": "{:%d.%m}"
    },

    "tray": {
        "spacing": 8
    },

    "hyprland/language": {
        "format": "{}",
        "format-en": "EN",
        "format-ru": "RU",
        "keyboard-name": "kingston-hyperx-alloy-fps-pro-mechanical-gaming-keyboard",
        "on-click": "hyprctl switchxkblayout kingston-hyperx-alloy-fps-pro-mechanical-gaming-keyboard next"
    },

    "memory": {
        "interval": 2,
        "format": "{used:4.1f}/{total:0.0f}G 󰾆"
    },

    "temperature": {
        "thermal-zone": 1,
        "format": "{temperatureC}°C "
    },

    "cpu": {
        "interval": 2,
        "format": "{usage:3}% 󰍛"
    },

    "pulseaudio": {
        "format": "{volume}% 󰕾",
        "format-muted": "󰝟",
        "scroll-step": 2,
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    },

    "network": {
        "format-wifi": "󰖟",
        "format-ethernet": "󰖟",
        "format-linked": "󰖟",
        "format-disconnected": "󰖟",
        "tooltip": true,
        "tooltip-format": "{ifname}\n{ipaddr}"
    }
}
```

Чтобы узнать название клавиатуры для модуля `hyprland/language`:

```bash
hyprctl devices
```

- ищем устройство с параметром `main: yes`

Узнать какой датчик отвечает за температуру процессора модуля `temperature`:

```bash
ls /sys/class/thermal/

cat /sys/class/thermal/thermal_zone*/type
```

- `ls`: выводит список датчиков, нас интересуют названия `thermal_zone` с номерами
- `cat`: выводит тип каждого `thermal_zone` по порядку номеров
- к примеру `cat` вывел `acpitz x86_pkg_temp`, значит датчик отвечающий за температуру процессора `thermal_zone1`, а не `thermal_zone0`.
- вводим итоговую цифру в модуль


```bash
nano ~/.config/waybar/style.css
```

```css
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
}

window#waybar {
    background: transparent;
    border: none;
    box-shadow: none;
    transition: background-color .5s;
}

.modules-left,
.modules-center,
.modules-right {
    background: rgba(15, 20, 25, .35);
    color: #fff;
    border: 2px solid rgba(23, 147, 209, .8);
    border-radius: 12px;
    padding: 3px 12px;
    margin: 8px 0;
    transition: all .2s ease;
}

.modules-left {
    margin-left: 16px;
}

.modules-right {
    margin-right: 16px;
}

#workspaces button {
    color: #fff;
    border-radius: 12px;
    padding: 0 8px;
    transition: all .2s ease;
}

#workspaces button:hover {
    background: transparent;
    box-shadow: none;
    text-shadow: none;
}

#workspaces button.active {
    color: #1793d1;
    text-shadow: 0 0 5px rgba(23, 147, 209, .8);
}

#cpu,
#temperature,
#network,
#language,
#memory,
#pulseaudio {
    border-right: 1px solid rgba(23, 147, 209, .25);
    padding-right: 14px;
    margin-right: 8px;
}

#memory {
    padding-right: 15px;
}

#language {
    padding-right: 11px;
}

#network.disconnected {
    color: #a0a0a0;
    
}

#clock.date {
    border-left: 1px solid rgba(23, 147, 209, 0.25);
    padding-left: 10px;
    margin-left: 8px;
}

#tray {
    border-right: none;
    padding-right: 0;
    margin-right: 0;
}
```

## Обои для рабочего стола

```bash
nano ~/.config/hypr/wallpaper.sh
```

```sh
while true; do
    IMG=$(find ~/Pictures/ -type f | shuf -n 1)
    awww img "$IMG" --resize fit
    sleep 600
done
```

- Поместите изображение для обоев в директорию `~/Pictures` 

## Wofi

```bash
nano ~/.config/wofi/style.css
```

```css
window {
    background: rgba(15,20,25,.50);
    border-radius: 12px;
    border: 1px solid rgba(23, 147, 209, .25);
}

#outer-box {
    padding: 12px;
    background: transparent;
}

#inner-box,
#scroll {
    background: transparent;
}

#input {
    background: rgba(15, 20, 25, .18);
    color: #1793d1;
    border-radius: 12px;
    padding: 8px;
    border: 1px solid rgba(23, 147, 209, .25);
}

#entry {
    padding: 6px;
}

#entry:selected {
    background: rgba(23,147,209,.22);
    border-radius: 12px;
    border: 1px solid rgba(23,147,209,.45);
}

#entry:selected #text {
    color: #1793d1;
    text-shadow: 0 0 3px rgba(23, 147, 209, .8);
}

#text {
    color: white;
}
```

## Kitty

```bash
nano ~/.config/kitty/kitty.conf
```

```ini
font_family JetBrainsMono Nerd Font
font_size 11

foreground #ffffff
background #0f1419

selection_foreground #1793d1
selection_background #175d82

cursor #1793d1
cursor_text_color #0f1419

color0 #10151b
color8 #555555

color1 #ff5555
color9 #ff6e67

color2 #50fa7b
color10 #5af78e

color3 #f1fa8c
color11 #f4f99d

color4 #1793d1
color12 #3fb5f1
color6 #1793d1
color14 #3fb5f1

color5 #ff79c6
color13 #ff92df

color7 #bbbbbb
color15 #ffffff

background_opacity 0.50

window_padding_width 12

window_border_width 0
draw_minimal_borders yes
```

## Fastfetch

```bash
nano ~/.config/fastfetch/config.jsonc
```

```jsonc
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "modules": [
    "title",
    "separator",
    "os",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "wm",
    "terminal",
    "cpu",
    "gpu",
    "memory",
    "disk",
    "break",
    "colors"
  ]
}
```

- если в системе несколько физических накопителей, вместо `disk` используйте `physicaldisk`.

---

# Запуск Hyprland

Запуск графической сессии Hyprland из TTY:

```bash
start-hyprland
```

---