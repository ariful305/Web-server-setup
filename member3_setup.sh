#!/bin/bash
set -euo pipefail

REPORT_DIR="$HOME/security_reports"
REPORT="$REPORT_DIR/member3_security_report_$(date +%F_%H-%M).txt"
SSHD="/etc/ssh/sshd_config"

BLUE="\e[34m"; RESET="\e[0m"

log() {
    printf "%b[SEC]%b %s\n" "$BLUE" "$RESET" "$*"
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        sudo cp "$file" "${file}.bak_$(date +%F_%H-%M)" || true
    fi
}

echo "=== MEMBER 3: SERVER SECURITY + FIREWALL + SSH HARDENING ==="

log "Creating report directory at $REPORT_DIR ..."
mkdir -p "$REPORT_DIR"

log "Installing security packages..."
sudo apt update -y
sudo apt install -y ufw fail2ban unattended-upgrades apt-listchanges

log "Configuring UFW firewall (reset + default deny incoming)..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH & Apache (http/https)
log "Allowing SSH and Apache Full through firewall..."
for rule in "OpenSSH" "Apache Full"; do
    sudo ufw allow "$rule" >/dev/null 2>&1 || true
done

sudo ufw --force enable

log "Hardening SSH configuration..."
backup_file "$SSHD"

# Use parameter expansion + sed via a loop for multiple settings
declare -A SSH_SETTINGS=(
    ["PermitRootLogin"]="no"
    ["PasswordAuthentication"]="no"
    ["PermitEmptyPasswords"]="no"
    ["LoginGraceTime"]="30"
)

for key in "${!SSH_SETTINGS[@]}"; do
    val="${SSH_SETTINGS[$key]}"
    if grep -qE "^#?\s*${key}" "$SSHD"; then
        sudo sed -i "s|^#\?\s*${key}.*|${key} ${val}|" "$SSHD"
    else
        echo "${key} ${val}" | sudo tee -a "$SSHD" >/dev/null
    fi
done

sudo systemctl reload sshd || sudo systemctl restart ssh || true

log "Configuring basic Fail2ban for sshd..."
JAIL_LOCAL="/etc/fail2ban/jail.d/ssh-hardening.conf"
sudo mkdir -p /etc/fail2ban/jail.d

sudo tee "$JAIL_LOCAL" >/dev/null <<EOF
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

log "Generating security report at $REPORT ..."
{
    echo "=== SERVER SECURITY REPORT (MEMBER 3) ==="
    echo "Generated: $(date)"
    echo
    echo "--- Firewall Status ---"
    sudo ufw status verbose
    echo
    echo "--- SSH Security Settings ---"
    grep -E 'PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords|LoginGraceTime' "$SSHD" || echo "SSH keys not found."
    echo
    echo "--- Fail2ban Status ---"
    sudo fail2ban-client status sshd 2>/dev/null || echo "Fail2ban sshd jail not active."
} > "$REPORT"

log "Report saved to $REPORT"
echo "=== MEMBER 3 COMPLETE ==="
