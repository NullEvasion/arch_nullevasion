# Сеть

```bash
ip a

nmtui

nmap -sn 192.168.12.0/24
```

Описание:

- `ip a`: вывод сетевых интерфейсов и IP-адресов
- `nmtui`: текстовый интерфейс для настройки NetworkManager
- `nmap -sn`: поиск активных устройств в локальной сети

## Подключение к Wi-Fi

```bash
iwctl

device list

station wlan0 scan

station wlan0 get-networks

station wlan0 connect имя_сети
```

Функции:

- `iwctl`: запуск консоли iwd для управления Wi-Fi
- `device list`: вывод названий адаптеров
- `station wlan0 scan`: сканирования сети
- `station wlan0 get-networks`: вывод всех Wi-Fi-сетей, которые отсканировал `scan`
- `station wlan0 connect имя_сети`: подключение к сети

Проверка работоспособности сети:

```bash
ping archlinux.org
```

## Выключение IPv6

Редактируем конфигурацию:

```bash
sudo nano /etc/sysctl.d/99-custom.conf
```


```ini
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
```

Применение изменений:

```bash
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

## Включение firewall

```bash
sudo ufw default deny incoming

sudo ufw default allow outgoing

sudo ufw enable

sudo ufw status verbose
```

- `deny incoming`: запрет входящих подключений. Для разрешения добавляем порт `ufw allow порт/tcp`, также  можно удалить `ufw delete номер`
- `allow outgoing`: разрешение на исходящие подключения
- `status verbose`: проверка, чтобы убедиться, что всё работает

---

# Установка пакетов

Перед установкой лучше прописать, для обновления ключей:

```bash
sudo pacman -Sy archlinux-keyring
```

Установка пакетов:

```bash
sudo pacman
yay
```

- для установки пакетов используем флаг `-S`, к примеру так: `sudo pacman -S пакет`, также с yay: `yay -S пакет`.
- флаг `-Rns` удаляет пакет вместе с неиспользуемыми конфигурациями и зависимостями.

Установка yay:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

Пакеты yay:

- `cameractrls-bin`: для вебки
- `brave-bin`: браузер
- `ventoy-bin`: для ISO образов
- `cnrdrvcups-lb-bin`: для принтеров
- `throne-bin`: прокси клиент
- `protonup-qt`: для windows игр
- `protontricks`: для старых windows игр

Пакеты pacman:

- `eza`: для красивого ls
- `awww`: для обоев рабочего стола
- `fastfetch`: информация о системе в терминале
- `reflector`: для зеркал
- `code`: это VS Code
- `pacman-contrib`: очистка пакетов через paccache
- `openbsd-netcat`: локальный обменник сообщениями
- `ufw`: firewall, защита сети
- `htop`: сводка о внутренностях пк
- `openssh`: для генерации ssh ключей
- `udisks2, udiskie`: для монтирования дисков
- `smartmontools`: для проверки дисков
- `nmap`: для скана сети активные IP-адреса
- `unarchiver`: предпросмотр архивов
- `gvfs`: для работы с USB, корзиной и т.д. для файловых менеджеров
- `gvfs-mtp`: для работы с Android по USB
- `gvfs-afc`: для работы с iPhone по USB
- `tumbler`: генерирует миниатюры изображений и видео
- `ffmpegthumbnailer`: делает превью видео
- `easyeffects lsp-plugins-lv2 calf mda.lv2 zam-plugins-lv2 distrho-ports-lv2 infamous-plugins-lv2`: для калибровки звука микрофона или наушников
- `samba`: для шейра папок
- `docker docker-compose`: контейнер для приложений
- `timeshift`: для снимков системы
- `thunar thunar-archive-plugin thunar-volman`: для файлового менеджера Thunar
- `cups cups-filters ghostscript gsfonts`: для принтеров
- `upower`: для вывода информации о батарее ноутбука
- `winetricks mesa-utils lib32-nvidia-utils lib32-mesa-utils`: для запуска старых игр

## Шрифты

- `ttf-liberation ttf-dejavu`
- `noto-fonts`
- `ttf-jetbrains-mono-nerd`
- `ttf-font-awesome`
- `noto-fonts-emoji`
- `noto-fonts-cjk`
- `noto-fonts-extra`
- `ttf-nerd-fonts-symbols`
- `ttf-firacode-nerd`

Для красивого шрифта и отображения кастомных иконок в системе:

```bash
fc-match "JetBrainsMono Nerd Font" && fc-match "Symbols Nerd Font"

gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 11"
```

---

# Настройки терминала

Редактируем файл конфигурации для удобного использования терминала:

```bash
nano ~/.bashrc
```

Конфигурация:

```ini
[[ $- != *i* ]] && return

alias ls='eza -a --icons --color=always --group-directories-first'
alias ll='eza -al --icons --color=always --group-directories-first'
alias grep='grep --color=auto'

fix-mirrors() {
    sudo reflector \
        --latest 20 \
        --country Russia,Germany,Netherlands \
        --age 12 \
        --protocol https \
        --sort rate \
        --save /etc/pacman.d/mirrorlist
}

null() {
    echo ":: Обновление ключей Arch Linux..."
    sudo pacman -Sy --needed --noconfirm archlinux-keyring || return

    echo ":: Запуск обновления системы..."
    yay -Syu --devel || {
        fix-mirrors
        echo ":: Повторная попытка обновления..."
        yay -Syu --devel || return
    }

    echo ":: Очистка кэша пакетов..."
    sudo paccache -r -k 2

    echo ":: Удаление ненужных AUR-зависимостей..."
    yay -Yc || true
    
    echo ":: Сохранение списка установленных пакетов..."
    pacman -Qqen | sort > ~/.pkg_native.txt
    pacman -Qqem | sort > ~/.pkg_aur.txt

    echo ":: Готово."
}

PS1='[\u@\h \W]\$ '
fastfetch
```

- `fix-mirrors`: нужен для качественного обновления зеркал. В параметре `country` подберите ближайшие для вас страны, для лучшей скорости загрузки
- `null`: предназначен для полного обновления системы
- `fastfetch`: при каждом запуске терминала - выводит информацию о системе

Применение настроек:

```bash
source ~/.bashrc
```

---

# Настройка программ

## Brave

Редактируем конфигурацию:

```bash
nano ~/.config/brave-flags.conf
```

```ini
--ozone-platform-hint=auto
--password-store=basic
--enable-features=WaylandWindowDecorations
--disable-gpu-driver-bug-workarounds
```

- `ozone-platform-hint`: автоматически определяет вашу графическую платформу
- `password-store`: отключение использования системного хранилища паролей, gnome, kwallet
- `enable-features`: включает рисование рамок и кнопок управления окном браузером через Wayland
- `disable-gpu-driver-bug-workarounds`: отключает костыли, которые Chromium применяет для конкретных драйверов видеокарт, если знает, что в них есть баги.
- также желательно выключить QUIC: brave://flags/#enable-quic


## Jellyfin

Создаём конфиги:

```bash
mkdir -p ~/jellyfin/config
mkdir -p ~/jellyfin/cache
sudo mkdir -p /etc/samba
sudo nano /etc/samba/smb.conf
```

```ini
[global]
   map to guest = Bad User
   usershare allow guests = yes

[Video]
   path = /home/имя_пользователь/Videos
   read only = yes
   guest ok = yes
   force user = имя_пользователь
```

Добавление Samba в автозапуск и перезапуск docker:

```bash
sudo systemctl enable --now smb.service nmb.service
sudo systemctl restart docker
```

Прописываем параметры docker:

```bash
nano ~/jellyfin/docker-compose.yml
```

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000
    network_mode: host
    restart: unless-stopped
    volumes:
      - /home/имя_пользователь/jellyfin/config:/config
      - /home/имя_пользователь/jellyfin/cache:/cache
      - /home/имя_пользователь/Videos:/media:ro
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

Запускаем docker:
```bash
docker compose up -d
```

Выставляем параметры уже на сервере http://localhost:8096:

- Добавляем медиатеку
- Playback - Transcoding
- Hardware acceleration - Nvidia NVENC
- Enable hardware decoding for - все галочки
- Enable enhanced NVDEC decoder +
- Enable hardware encoding +
- Allow encoding in HEVC format +
- Enable Tone mapping +
- Encoding preset - superfast
- Throttle Transcoding +
- Если видео выводит мало fps: лимит битрейта во время просмотра видео поставить 15 Мбит/с

Примечание:

- если в системе установлен пакет `ufw` с параметром `deny incoming`, то нужно открыть порт 8096 `sudo ufw allow 8096/tcp`

## CUPS

```bash
sudo systemctl enable --now cups

yay -S cnrdrvcups-lb-bin
```

- настройка: http://localhost:631 Администрирование - Добавить принтер


## Upower

Вывод информации о батарее ноутбука:

```bash
upower -i $(upower -e | grep BAT)

upower -d
```

## Ventoy, udisks2, udiskie, smartmontools

```bash
lsblk

sudo smartctl -a /dev/nvme0n1

sudo umount /dev/sdb

sudo ventoy -i /dev/sdb
```

- `lsblk`: список всех дисков, видимых системе
- `smartctl -a`: вывод информации о конкретном диске
- `umount`: размонтировать диск
- `ventoy -i`: установить Ventoy на диск. ВНИМАНИЕ: Стирает все данные на накопителе!

## Paccache

```bash
sudo paccache -rk0
```

- `-rk0 -rk2 -rk3`: флаг `-rk3` оставляет 3 пакета, `-rk2` оставляет 2 пакета `-rk0` удаляет все пакеты
- не рекомендуется постоянно использовать `-rk0`, так как исчезает возможность отката пакетов.

## Netcat

Пример для работы между двумя компьютерами:

ПК1:

```bash
nc -l -p 9999
```

ПК2:

```bash
nc 192.168.1.15 9999
```

- `-l -p`: флаги включающие прослушивание на порту первого компьютера, обычно для netcat это 9999 порт
- `nc айпи порт`: подключение к слушающему узлу, чтобы узнать айпи первого компьютера пропишите `ip a`

## Throne

Даём права ядру sing-box для работы TUN-режима

```bash
sudo chown root:root /opt/Throne/ThroneCore
sudo chmod u+s /opt/Throne/ThroneCore
```

В настройках Маршрутизации, во вкладке Маршрут, выставляем данные параметры, если требуется чтобы прокси работал по правилам:

Outbound по умолчанию: direct
Напрямую: пусто
Прокси:

```ini
domain:testingcf.jsdelivr.net
domain:cdn.jsdelivr.net
suffix:jsdelivr.net
suffix:rutrk.org
ruleset:geosite-discord
ruleset:geosite-youtube
ruleset:geosite-google
ruleset:geosite-telegram
ruleset:geosite-twitter
ruleset:geosite-instagram
ruleset:geosite-whatsapp
```

Блокировать: пусто

- в `Прокси` привёл примеры доменов
- Таким образом прокси клиент будет прогонять через себя данные домены, а остальные будет отправлять мимо

---

# Прочее

## Поиск файлов

```bash
sudo find / \( -iname "имя" -o -iname "ещё_имя.*" \) 2>/dev/null
```

- в `ещё_имя.*` символ `*` говорит системе искать файлы с любыми символами после `.`, к примеру `photo.jpg` и `photo.jpeg`

## Wpctl

```bash
wpctl status

wpctl set-default номер
```

- `status`: вывод списка аудио и видео, `*` - дефолт
- `set-default`: поменять дефолтное значение

## Oblivion Lost Remake 3.0

Узнаём Wine Prefix ID игры:
```bash
protontricks -l
```

- перед этим сначала запускаем игру, посредством добавления .exe в библиотеку Steam и активации Совместимости с Proton
- это нужно для создания Wine-префикса

Ставим нужные драйвера:

```bash
protontricks 4269973641 d3dx9 openal d3dcompiler_43
```

Добавляем параметры запуска в Steam:

```ini
PULSE_LATENCY_MSEC=60 WINEDLLOVERRIDES="openal32=n,b;dsound=n,b" %command% -ltx user_risotto.ltx -simple_script_lua_debug -simple_lua_debug
```

---