```ini
# #######################################################################################
#                                                                                       #
#   Arch Linux                                                                          #
#   Kernel: 7.2.6                                                                       #
#                                                                                       #
# #######################################################################################
```

# Настройка SSH

Создаём ключ SSH на устройстве, с которого будем заходить на сервер:

```bash
ssh-keygen -t ed25519 -C "arch-pc" -f ~/.ssh/имя
```

Копируем публичный ключ:

```bash
cat ~/.ssh/имя.pub
```

Сохраняем его — он понадобится в процессе работы `null.sh`

## Обновление системы и установка 3x-ui

Обновляем систему и перезагружаем сервер:

```bash
pacman -Syu && reboot
```

После перезапуска снова подключаемся и запускаем скрипт:


```bash
curl -fsSL https://raw.githubusercontent.com/NullEvasion/arch_nullevasion/refs/heads/main/null.sh -o /tmp/null.sh

bash /tmp/null.sh
```

- во время установки `null.sh` попросит вставить публичный SSH-ключ.

---

# Настройка панели 3x-ui

## Создание подключения

```text
После установки скрипт выведет данные в блоке:

==== Готово ====

Панель 3x-ui работает на 127.0.0.1:28781 и доступна через SSH-туннель.

После подключения к серверу через SSH панель открывается на локальном компьютере по адресу:

http://127.0.0.1:28781/webBasePath

webBasePath и данные для входа берём из вывода скрипта.
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


Заходим в раздел Клиенты и создаём новое подключение:

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