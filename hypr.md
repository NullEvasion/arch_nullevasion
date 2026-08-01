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

## Hyprland.conf

```bash
nano ~/.config/hypr/hyprland.conf
```

```ini
env = LIBVA_DRIVER_NAME,radeonsi
env = XDG_SESSION_TYPE,wayland
env = GTK_THEME,Colloid-Dark-Black

monitor = DP-2,1440x900@59.89,auto,1

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user start hyprpolkitagent
exec-once = waybar
exec-once = mako
exec-once = awww-daemon
exec-once = sleep 3 && easyeffects --gapplication-service
exec-once = ~/.config/hypr/wallpaper.sh
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

bind = SUPER, M, exit
bind = SUPER, C, killactive
bind = SUPER, Q, exec, kitty
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, E, exec, thunar
bind = SUPER, F, fullscreen, 0
bind = SUPER, UP, movefocus, u
bind = SUPER, X, togglefloating
bind = SUPER, LEFT, movefocus, l
bind = SUPER, DOWN, movefocus, d
bind = SUPER, RIGHT, movefocus, r
bind = SUPER SHIFT, C, forcekillactive
bind = SUPER SHIFT, R, exec, hyprctl reload
bind = SUPER, Z, exec, hyprshot -m region --clipboard-only
bind = SUPER, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
bind = SUPER, R, exec, wofi --show drun --normal-window --style ~/.config/wofi/style.css

bindel = SUPER, A, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindel = SUPER, D, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle, compose:ralt
    follow_mouse = 1
}

decoration {
    rounding = 12
    active_opacity = 1.0
    inactive_opacity = 1.0

    shadow {
        enabled = true
        range = 18
        render_power = 3
        color = rgba(00000055)
    }

    blur {
        enabled = true
        size = 4
        passes = 2
        new_optimizations = true
        ignore_opacity = true
        xray = false
        noise = 0.008
        contrast = 1.0
        brightness = 1.0
    }
}

general {
    border_size = 2
    col.active_border = rgb(1793d1) rgb(33ccff) 45deg
    col.inactive_border = rgba(1793d11a)
    gaps_in = 5
    gaps_out = 10
}

animations {
    enabled = true
    bezier = smooth, 0.25, 1, 0.5, 1
    animation = windows, 1, 5, smooth
    animation = windowsOut, 1, 5, smooth
    animation = border, 1, 8, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 6, smooth

}

layerrule = blur on, match:namespace all
windowrule = opacity 0.95, match:namespace all
```
Параметры `env` для Nvidia нужны такие:

- env = LIBVA_DRIVER_NAME,nvidia
- env = XDG_SESSION_TYPE,wayland
- env = GTK_THEME,Colloid-Dark
- env = GBM_BACKEND,nvidia-drm
- env = __GLX_VENDOR_LIBRARY_NAME,nvidia

Параметры монитора, для `monitor` можно узнать командой:

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