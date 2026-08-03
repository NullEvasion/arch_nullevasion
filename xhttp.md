# Установка защиты и 3x-ui

```bash
ssh root@айпи

apt install fail2ban ufw

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

- `ssh root@айпи`: подключение к серверу.
- `fail2ban`: нужен для защиты от перебора паролей SSH.
- `ufw`: файрволл.
- `curl -Ls`: скачивание и запуск установщика 3x-ui.

Во время установки:

- рекомендуется указать нестандартный порт, к примеру `28781`.

После установки:

- копируем логин и пароль, авторизуемся в панели.
- IP-адрес управления панелью ставим `127.0.0.1` и порт `28781`.

---


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

- теперь для входа на сервер можем всегда писать `ssh имя`.

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

Проверяем конфиг на наличее опечаток:

```bash
sshd -t
```

## Настройка ufw

```bash
ufw allow 24813/tcp

ufw allow 443/tcp

ufw default deny incoming

ufw default allow outgoing

ufw enable
```
- `24813`: порт сервера.
- `443`: порт инбаунда.
- `deny incoming`: запрещает входящие подключения.
- `allow outgoing`: разрешает исходящие подключения.

## Применение настроек и запуск служб

```bash
systemctl enable fail2ban

systemctl enable nftables

systemctl enable ssh

systemctl restart fail2ban

systemctl restart nftables

systemctl restart ssh
```

- после перезапуска ssh чистим хосты `ssh-keygen -R ip_адрес_сервера` и перезаходим на сервер.
- если не пускает то прописываем `sudo systemctl disable --now ssh.socket && sudo systemctl enable --now ssh` через VNC, на сайте хостера.

---

# Настройка панели 3x-ui

Заходим в панель:

```text
https://IP_устройства:28781/URL_PATH
```

- `URL_PATH`: генерируется во время установки 3x-ui.

Пример:

```text
https://192.168.150.8:28781/qmKoOMN2UIr9bLDNDC
```

Заходим в раздел Подключения и создаём новое подключение:

- `Listen IP`: айпи_адрес_сервера
- `Port`: 443
- `Protocol`: VLESS
- `Security`: Reality
- `Transport`: XHTTP
- `uTLS`: firefox
- `Target`: www.python.org:443
- `SNI`: www.python.org

Пояснения:

- `Target www.python.org:443`: это пример. При необходимости можно использовать другой сайт. Параметры `SNI` должны соответствовать выбранному `Target`.

Если требуется лучшая маскировка заходим в Конфигурацию Xray - Маршрутизация:

```text
Inbound Tags: api
Outbound Tag: api

Domain: regexp:.*\.ru$,regexp:.*\.su$,regexp:.*\.rf$,regexp:.*yandex.*,regexp:.*\.рф$,regexp:.*mail\.ru$
Outbound Tag: blocked

Protocol: bittorrent
Outbound Tag: blocked

Network: tcp, udp
Outbound Tag: direct
```

- правила `regexp:.*\.ru$`, `regexp:.*\.rf$` и т.д., блокируют подключения к русским доменам для уменьшения шанса обнаружения зарубежного трафика во время использования VPN. 

---

# Команды для диагностики

```bash
ss -tlnp

journalctl -f

ssh -O exit имя

export TERM=xterm
```

- `ss -tlnp`: проверка портов
- `journalctl -f`: проверка логов
- `ssh -O exit имя`: выход с сессии ssh
- `export TERM=xterm`: если ругается на терминал Kitty

---