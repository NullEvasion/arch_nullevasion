# Установка защиты и 3x-ui

```bash
ssh root@айпи

apt install fail2ban nftables

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

- `ssh root@айпи`: подключение к серверу.
- `fail2ban`: нужен для защиты от перебора паролей SSH.
- `nftables`: файрволл.
- `curl -Ls`: скачивание и запуск установщика 3x-ui.
- рекомендуется указать нестандартный порт, к примеру `28781`.

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

- `24813`: порт SSH
- `443`: порт XRAY

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

- после перезапуска ssh чистим хосты `ssh-keygen -R ip_адрес_сервера` и перезаходим на сервер.
- если не пускает то прописываем `sudo systemctl disable --now ssh.socket && sudo systemctl enable --now ssh` через VNC, на сайте хостера.

---

# Настройка панели 3x-ui

## Создание подключения

Узнаём IP-адрес устройства:

```bash
ip route get 1.1.1.1 | awk '{print $7; exit}'
```

Заходим в панель:

```text
https://127.0.0.1:28781/webBasePath
```

- чтобы найти `webBasePath` надо прописать `x-ui` и выбрать `View Current Settings`

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

# Настройка маршрутизации

Заходим в Конфигурацию Xray - Маршрутизация и создаём правила строго в данной последовательности:

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

```text
Правила маршрутизации проверяются сверху вниз.

После первого совпадения дальнейшая проверка прекращается.

Поэтому сначала должны идти все правила, отправляющие трафик через `proxy`, затем правило блокировки `bittorrent`, а последним должно находиться правило:

Network: tcp, udp
Outbound Tag: direct

Оно является правилом по умолчанию и отправляет весь оставшийся TCP и UDP трафик напрямую.
```

---

# Команды для диагностики

- `ss -tlnp`: проверка портов.
- `journalctl -f`: проверка логов.
- `ssh -O exit имя`: выход с сессии ssh на устройстве, с которого заходили на сервер.
- `export TERM=xterm`: если ругается на терминал Kitty.
- `systemctl status`: проверка работоспособности: `x-ui`, `ssh` и прочего, с выводом последних логов.

---