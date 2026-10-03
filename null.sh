#!/bin/bash
set -euo pipefail

[[ $EUID -eq 0 ]] || {
    echo "Запусти скрипт от root."
    exit 1
}

SSH_PORT=24813
XUI_PORT=28781
XUI_INSTALLER_URL="https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh"

echo
echo "==== NullEvasion Arch VPS setup ===="
echo

echo "[1/6] Установка пакетов..."

pacman -S --needed --noconfirm \
    base \
    linux \
    sudo \
    nano \
    git \
    networkmanager \
    openssh \
    nftables \
    fail2ban \
    curl \
    wget \
    htop \
    rsync \
    smartmontools \
    reflector

systemctl enable --now NetworkManager
systemctl enable --now sshd

echo
echo "[2/7] Установка 3x-ui..."
echo

export XUI_NONINTERACTIVE=1
export XUI_PANEL_PORT="$XUI_PORT"

curl -fsSL "$XUI_INSTALLER_URL" | bash

/usr/local/x-ui/x-ui setting -listenIP "127.0.0.1" >/dev/null 2>&1 || \
/usr/bin/x-ui setting -listenIP "127.0.0.1" >/dev/null 2>&1 || true

systemctl restart x-ui

XUI_RESULT="/etc/x-ui/install-result.env"

if [[ -f "$XUI_RESULT" ]]; then
    source "$XUI_RESULT"
fi

echo
echo "[3/6] Настройка fail2ban..."
echo

mkdir -p /etc/fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
EOF

systemctl enable --now fail2ban

echo
echo "[4/6] Настройка sysctl..."
echo

cat > /etc/sysctl.d/99-null.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

net.ipv4.tcp_syncookies = 1
net.core.somaxconn = 4096

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF

sysctl --system >/dev/null

echo
echo "[5/6] Настройка SSH..."
echo

read -r -p "SSH public key: " SSH_KEY < /dev/tty

[[ -n "$SSH_KEY" ]] || {
    echo "SSH key не указан."
    exit 1
}

mkdir -p /root/.ssh
chmod 700 /root/.ssh

printf '%s\n' "$SSH_KEY" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

mkdir -p /root/.ssh/sockets
chmod 700 /root/.ssh/sockets

cat > /etc/ssh/sshd_config.d/99-null.conf <<EOF
Port $SSH_PORT
LoginGraceTime 20
PermitRootLogin prohibit-password
MaxAuthTries 3
PasswordAuthentication no
ClientAliveInterval 60
ClientAliveCountMax 3
MaxStartups 100:30:200
EOF

sshd -t
systemctl restart sshd

echo
echo "[6/6] Настройка nftables..."
echo

cat > /etc/nftables.conf <<'EOF'
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
EOF

nft -c -f /etc/nftables.conf
systemctl enable --now nftables
nft -f /etc/nftables.conf

echo
echo "==== Готово ===="
echo
echo "SSH:       $SSH_PORT"
echo "3x-ui:     http://127.0.0.1:$XUI_PORT$XUI_WEB_BASE_PATH"
echo "Логин:     $XUI_USERNAME"
echo "Пароль:    $XUI_PASSWORD"
echo