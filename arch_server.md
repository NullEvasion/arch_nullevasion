```ini
# #######################################################################################
#                                                                                       #
#   Arch Linux Server                                                                   #
#   Device: Asus M60J                                                                   #
#                                                                                       #
# #######################################################################################
```

# Разметка диска

Выбираем подходящий диск и начинаем размечать систему:

```bash
lsblk

cfdisk /dev/nvme0n1
```

Пример разметки разделов:

- /dev/nvme0n1p1 1 ГБ EFI System.
- /dev/nvme0n1p2 4 ГБ Linux swap.
- /dev/nvme0n1p3 Оставшееся пространство Linux root (x86-64).

```text
Размер swap зависит от объёма ОЗУ и необходимости использования гибернации. На данном устройстве 8 ГБ ОЗУ, следовательно, для `swap` желательно выделить половину - то есть 4 ГБ. `swap` не нужен при объёме ОЗУ выше 8 ГБ
```

## Форматирование системы

Форматируем диск:

```bash
mkfs.vfat -F 32 /dev/nvme0n1p1

mkfs.ext4 /dev/nvme0n1p3
```

- `mkfs.vfat`: форматирует EFI-раздел в FAT32.
- `mkfs.ext4`: форматирует корневой раздел в ext4.

Инициализируем и включаем Swap:

```bash
mkswap /dev/nvme0n1p2

swapon /dev/nvme0n1p2
```

## Монтирование системы

Создаём директорию для EFI-загрузчика и монтируем его:

```bash
mount /dev/nvme0n1p3 /mnt

mkdir -p /mnt/boot

mount /dev/nvme0n1p1 /mnt/boot
```

---

# Подготовка системы

## Установка пакетов

```bash
pacstrap -K /mnt \
base linux linux-firmware intel-ucode \
base-devel sudo nano git networkmanager \
openssh nftables fail2ban \
reflector curl wget \
htop rsync smartmontools
```

- `base`: минимальный набор для работы системы (pacman, coreutils, findutils, grep, sed).
- `linux`: ядро.
- `linux-firmware`: прошивки для оборудования.
- `intel-ucode`: для исправления ошибок процессора.
- `base-devel`: набор утилит для компиляции и сборки программ из исходного кода.
- `sudo`: выполнение команд с правами администратора из-под обычного пользователя.
- `nano`: терминальный текстовый редактор.
- `git`: система контроля версий для клонирования и обновления репозиториев.
- `networkmanager`: служба для управления сетевыми подключениями.
- `openssh`: SSH-сервер и клиент для удалённого подключения и передачи файлов.
- `nftables`: современный встроенный файрвол Linux для фильтрации сетевого трафика.
- `fail2ban`: защита от перебора паролей путём временной блокировки IP-адресов.
- `curl`: для передачи данных по HTTP, HTTPS, FTP и другим протоколам.
- `wget`: для скачивания файлов по сети.
- `htop`: интерактивный монитор процессов и ресурсов системы.
- `rsync`: утилита для быстрого копирования и синхронизации файлов и каталогов.
- `smartmontools`: утилиты для проверки состояния и диагностики HDD и SSD.
- `reflector`: автоматически подбирает и обновляет список самых быстрых зеркал Arch Linux.

## Прочие настройки

Генерируем таблицу монтирования файловых систем:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Переходим с флешки внутрь системы:

```bash
arch-chroot /mnt
```

Включаем сетевые службы:

```bash
systemctl enable NetworkManager

systemctl enable sshd

systemctl enable nftables

systemctl enable fail2ban
```

Создаём конфигурацию для хука:

```bash
nano /etc/mkinitcpio.conf
```

Изменяем строки HOOKS и MODULES:

```ini
HOOKS=(base autodetect microcode modconf keyboard block filesystems fsck)
MODULES=()
```

Применяем настройки:

```bash
mkinitcpio -P
```

Настраиваем часовой пояс:

```bash
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

hwclock --systohc
```

Даём имя компьютеру:

```bash
echo "arch-server" > /etc/hostname
```

Задаём пароль для root:

```bash
passwd
```

Добавляем кастомную команду для обновления зеркал:

```bash
nano ~/.bashrc
```

```ini
fix-mirrors() {
    sudo reflector \
        --latest 20 \
        --country Russia,Germany,Netherlands \
        --age 12 \
        --protocol https \
        --sort rate \
        --save /etc/pacman.d/mirrorlist
}
```

## Настройка языка

Настраиваем отображение языков в системе:

```bash
nano /etc/locale.gen
```

Расскоментировать:

```ini
en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
```

```bash
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

- `locale-gen`: генерируем выбранные локали
- `echo "LANG=en_US.UTF-8" > /etc/locale.conf`: устанавливает локаль системы по умолчанию

## Работа с загрузчиком

Устанавливаем загрузчик GRUB:

```bash
pacman -S grub efibootmgr

grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg
```

Прописываем для вывода UUID:

```bash
blkid -s UUID -o value /dev/nvme0n1p3
```

- далее надо подставить его вместо параметра `UUID_ROOT` в `arch.conf`.

Редактируем конфигурацию загрузчика:

```bash
nano /boot/loader/entries/arch.conf
```

```ini
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=UUID_ROOT rw
```

Редактируем основную конфигурацию загрузчика:

```bash
nano /boot/loader/loader.conf
```

```ini
default arch.conf
timeout 3
console-mode max
editor no
```

---

# Перезапуск

```bash
exit
umount -R /mnt
swapoff -a
reboot
```

- в промежутке перезапуска - вытаскиваем загрузочный диск.

Авторизуемся под root и создаём пользователя:

```bash
useradd -m -G wheel -s /bin/bash имя

passwd имя
```

Разрешаем пользователю использовать sudo:

```bash
EDITOR=nano visudo
```

Расскоментировать строку:

```ini
%wheel ALL=(ALL:ALL) ALL
```

Выходим с root и заходим с созданного пользователя

Подключаемся к Wi-Fi если нет возможности подключиться по кабелю:

```bash
nmtui
```

---

# Установка 3x-ui

```bash
curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh | sudo bash
```

- `curl -Ls`: скачивание и запуск установщика 3x-ui.

Во время установки:

- рекомендуется указать нестандартный порт, к примеру `28781`

---

Все дальнейшие команды выполняются через `sudo`.

# Настройка fail2ban

```bash
nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
backend = systemd

[sshd]
enabled = true
port = 24813
filter = sshd
maxretry = 3
bantime = 3600
findtime = 600
```

---

# Базовая настройка сервера

Открываем файл конфигурации:

```bash
nano /etc/sysctl.conf
```

```ini
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

net.ipv4.tcp_syncookies = 1

net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

net.core.somaxconn = 4096

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
```

Применяем настройки:

```bash
sysctl -p
```

## Настройка SSH

Создаём ключ SSH на устройстве, с которого будем заходить на сервер:

```bash
ssh-keygen -t ed25519 -C "arch-pc" -f ~/.ssh/имя
```

Копируем ключ:

```bash
cat ~/.ssh/имя.pub
```

Создаём директорию и файлы SSH на сервере:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh

touch ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys

mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets
```

Вставляем ключ:

```bash
nano ~/.ssh/authorized_keys
```

Автоматизируем вход на сервер:

```bash
nano ~/.ssh/config
```

```ini
Host имя
	HostName IP_АДРЕС_СЕРВЕРА
	User root
	Port 24813
	IdentityFile ~/.ssh/имя
	LocalForward 28781 127.0.0.1:28781
	ControlMaster auto
	ControlPath ~/.ssh/sockets/%r@%h-%p
	ControlPersist 600
	ServerAliveInterval 60
	ServerAliveCountMax 3
```

- теперь для входа на сервер можем всегда писать `ssh имя`

Запрещаем вход по паролю и стабилизируем туннель:

```bash
nano /etc/ssh/sshd_config
```

```ini
Port 24813
LoginGraceTime 20
PermitRootLogin prohibit-password
MaxAuthTries 3
PasswordAuthentication no
ClientAliveInterval 60
ClientAliveCountMax 3
MaxStartups 100:30:200
```

Проверяем конфиг на наличие опечаток:

```bash
sshd -t
```

## Настройка nftables

```bash
nano /etc/nftables.conf
```

```nft
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        iif lo accept

        ct state established,related accept

        tcp dport { 24813, 443 } accept

        ip protocol icmp accept
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
```

- `24813`: SSH
- `443`: XRAY

Проверка конфига nftables на ошибки:

```bash
nft -c -f /etc/nftables.conf
```

Проверка открытых портов:

```bash
ss -tlnp | grep -E '24813|443|28781'
```

## Применение настроек и запуск служб

```bash
systemctl enable --now fail2ban

systemctl enable --now nftables

systemctl enable --now sshd
```

---

# Настройка 3x-ui

## Создание подключения

Узнаём IP-адрес устройства:

```bash
ip route get 1.1.1.1 | awk '{print $7; exit}'
```

Заходим в панель:

```text
https://127.0.0.1:28781/webBasePath
```

- чтобы найти `webBasePath` надо прописать `sudo x-ui` и выбрать `View Current Settings`

Заходим в раздел Клиенты и создаём новое подключение:

- `Listen IP`: 0.0.0.0
- `Стратегия адреса для ссылок`: Пользовательская
- `Пользовательский адрес для ссылок`: IP_адрес_сервера
- `Port`: 443
- `Protocol`: VLESS
- `Security`: Reality
- `Transport`: XHTTP
- `uTLS`: firefox
- `Target`: www.python.org:443
- `SNI`: www.python.org

Пояснение:

- `Target`: любой HTTPS-сайт, поддерживающий HTTP/2 или HTTP/3. `SNI` должен совпадать с `Target`.

## Настройка маршрутизации

В разделе `Исходящие` нужно импортировать ссылку на прокси клиент VPS и нажать `Создать`

- после импорта откройте раздел Основное и вписываете в «Тег» имя `proxy`

Заходим в Конфигурацию Xray - Маршрутизация:

```text
Inbound Tags: api
Outbound Tag: api

Inbound Tags: in-443-tcp
Outbound Tag: proxy

Domain: 
suffix:jsdelivr.net,suffix:rutrk.org,suffix:challenges.cloudflare.com,suffix:wallhere.com,suffix:static.wikia.nocookie.net,suffix:githubusercontent.com,keyword:rutracker,keyword:redgifs,ruleset:geosite-discord,ruleset:geosite-youtube,ruleset:geosite-google,ruleset:geosite-openai,ruleset:geosite-telegram,ruleset:geosite-twitter,ruleset:geosite-instagram,ruleset:geosite-whatsapp,ruleset:geosite-intel
Outbound Tag: proxy

Protocol: bittorrent
Outbound Tag: blocked

Network: tcp, udp
Outbound Tag: direct
```

- `Outbound Tag: proxy`: должен совпадать с `tag` импортированного исходящего подключения к VPS

```text
Правила маршрутизации проверяются сверху вниз.

После первого совпадения дальнейшая проверка прекращается.

Поэтому сначала должны идти все правила, отправляющие трафик через `proxy`, затем правило блокировки `bittorrent`, а последним должно находиться правило:

Network: tcp, udp
Outbound Tag: direct

Оно является правилом по умолчанию и отправляет весь оставшийся TCP и UDP трафик напрямую.
```

---