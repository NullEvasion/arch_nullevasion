# Установка 3x-ui

```bash
ssh root@айпи

apt update && apt upgrade -y

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

- `ssh root@айпи`: подключение к серверу
- `apt update && apt upgrade -y`: обновление системы
- `curl -Ls`: скачивание и запуск установщика 3x-ui

Во время установки:

- порт можно указать вручную
- рекомендуется указать нестандартный порт
- пример `28781`
- при настройке SSL выбрать `0`

После установки:

- Копируем логин и пароль, авторизуемся на сервере
- IP-адрес управления панелью ставим `127.0.0.1` и порт `28781`

---

# Установка fail2ban

```bash
apt install fail2ban -y

systemctl enable fail2ban

systemctl start fail2ban
```

- `fail2ban`: для защиты от перебора паролей SSH

## Настройка fail2ban

```bash
nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
port = 24813
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

Перезапускаем fail2ban для применения настроек:

```bash
systemctl restart fail2ban
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
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 5
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.somaxconn = 4096
net.ipv4.tcp_fin_timeout = 20
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
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

## Настройка firewall

```bash
apt install ufw -y

ufw allow 24813/tcp

ufw allow 443/tcp
```

- `24813`: порт сервера
- `443`: порт инбаунда

```bash
ufw default deny incoming

ufw default allow outgoing

ufw enable
```

- `deny incoming`: запрещает входящие подключения
- `allow outgoing`: разрешает исходящие подключения

## Запуск SSH:

```bash
systemctl enable ssh

systemctl restart ssh
```

- перезапуск ssh. После этого чистим хосты `ssh-keygen -R ip_адрес_сервера` и перезаходим на сервер
- если не пускает то прописываем `sudo systemctl disable --now ssh.socket && sudo systemctl enable --now ssh` через VNC на сайте провайдера

---

# Настройка панели 3x-ui

Заходим на сервер и создаём подключение с данными параметрами:

- Listen IP айпи_адрес_сервера
- Порт 443
- Протокол VLESS
- Security Reality
- Flow -
- Транспорт XHTTP
- uTLS firefox
- Target www.python.org:443
- SNI www.python.org

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

- Правило `Domain: regexp` уменьшает вероятность того, что трафик к российским сайтам будет проходить через VPN

---

# Команды для диагностики

```bash
ss -tlnp | grep ssh

ss -tlnp

journalctl -u ssh -f

ssh -O exit имя

export TERM=xterm
```

- `ss -tlnp | grep ssh`: проверить, какие порты слушает SSH
- `ss -tlnp`: проверить вообще все порты
- `journalctl -u ssh -f`: проверить логи при проблемах
- `ssh -O exit имя`: выход с сессии ssh
- `export TERM=xterm`: если ругается на терминал Kitty

---