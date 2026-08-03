```ini
# #######################################################################################
#                                                                                       #
#   Cyberdeck                                                                           #
#   Device: CHUWI Ubox (CWI604H)                                                        #
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

- /dev/nvme0n1p1 1 ГБ EFI System
- /dev/nvme0n1p2 16 ГБ Linux swap
- /dev/nvme0n1p3 Оставшееся пространство Linux root (x86-64)
- размер swap зависит от объёма ОЗУ и необходимости использования гибернации

## Создание LUKS-контейнера и форматирование системы

Создаём LUKS-контейнер:

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p3

cryptsetup open /dev/nvme0n1p3 cryptroot
```

- `luksFormat --type luks2 /dev/nvme0n1p3`: создаёт шифрованный LUKS-контейнер
- `open /dev/nvme0n1p3 cryptroot`: открывает контейнер

Форматируем диск:

```bash
mkfs.vfat -F 32 /dev/nvme0n1p1

mkfs.ext4 /dev/mapper/cryptroot
```

- `mkfs.vfat`: форматирует EFI-раздел в FAT32
- `mkfs.ext4`: форматирует открытый LUKS-контейнер в ext4

Инициализируем и включаем Swap:

```bash
mkswap /dev/nvme0n1p2

swapon /dev/nvme0n1p2
```

## Монтирование системы

Монтируем зашифрованный корень:

```bash
mount /dev/mapper/cryptroot /mnt
```

Создаём директорию для EFI-загрузчика и монтируем его:

```bash
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
mtools mesa vulkan-radeon \
lib32-mesa lib32-vulkan-radeon \
libva-mesa-driver libva-utils \
xorg-xwayland
```

- `sudo`: выполнение команд с правами администратора из-под обычного пользователя
- `pacman`: пакетный менеджер
- `base`: минимальный набор для работы системы (pacman, coreutils, findutils, grep, sed)
- `linux`: ядро
- `linux-firmware`: прошивки для оборудования
- `amd-ucode`: для исправления ошибок процессора Для intel нужен пакет `intel-ucode`
- `nano`: терминальный текстовый редактор
- `mtools`: набор утилит для работы с MS-DOS/FAT
- `networkmanager`: служба для управления сетевыми подключениями
- `xorg-xwayland`: обеспечивает запуск X11-приложений в окружении Wayland, для стабильного запуска старых приложений
- `git`: система контроля версий для клонирования и обновления репозиториев
- `base-devel`: набор утилит для компиляции и сборки программ из исходного кода
- `mesa`: графические библиотеки Mesa с поддержкой OpenGL и Vulkan
- `vulkan-radeon`: драйвер Radeon для поддержки графического API Vulkan для Windows-игр
- `lib32-mesa`: 32 битная версия основного драйвера
- `lib32-vulkan-radeon`: 32 битная версия Vulkan-драйвера
- `libva-mesa-driver`: драйвер для аппаратного ускорения видео
- `libva-utils`: набор консольных утилит для проверки и тестирования аппаратного ускорения видео

## Прочие настройки

Включаем репозиторий multilib для установки 32-битных библиотек:

```bash
nano /etc/pacman.conf
```

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Генерируем таблицу монтирования файловых систем:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Переходим с флешки внутрь системы:

```bash
arch-chroot /mnt
```

Включаем сетевую службу:

```bash
systemctl enable NetworkManager
```

Создаём конфигурацию для хука encrypt:

```bash
nano /etc/mkinitcpio.conf
```

Изменяем строки HOOKS и MODULES:

```ini
HOOKS=(base autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
MODULES=(amdgpu)
```

- хук `encrypt` нужен для доступа к зашифрованному разделу на этапе загрузки

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
echo "hostname" > /etc/hostname
```

Задаём пароль для root:

```bash
passwd
```

## Настройка языка

Создаём конфигурацию для языка терминала:

```bash
nano /etc/vconsole.conf
```

```ini
KEYMAP=us
FONT=cyr-sun16
```

- `KEYMAP=us`: задаёт раскладку клавиатуры в TTY
- `FONT=cyr-sun16`: загрузка шрифта, содержащего кириллицу, для отображения русского языка в TTY

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

echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
```

- `locale-gen`: генерируем выбранные локали
- `echo "LANG=ru_RU.UTF-8" > /etc/locale.conf`: устанавливает локаль системы по умолчанию

## Работа с загрузчиком

Устанавливаем загрузчик systemd-boot:

```bash
bootctl install
```

Редактируем конфигурацию загрузчика для LUKS-контейнера:

```bash
nano /boot/loader/entries/arch.conf
```

```ini
title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options cryptdevice=UUID=UUID_LUKS:cryptroot root=/dev/mapper/cryptroot rw
```

- чтобы узнать `UUID_LUKS` прописываем `blkid -s UUID -o value /dev/nvme0n1p3`

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
cryptsetup close cryptroot
reboot
```

- в промежутке перезапуска - вытаскиваем загрузочный диск

Авторизуемся под root и создаём пользователя:

```bash
useradd -m -G wheel,audio,video,storage,input,lp -s /bin/bash имя

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