#!/bin/bash
echo "=== MEMBER 3: SERVER SECURITY + FIREWALL + SSH HARDENING ==="

########################################
# 1. Install Security Tools
########################################
echo "[1] Installing security packages..."
sudo apt update
sudo apt install -y ufw fail2ban unattended-upgrades apt-listchanges

########################################
# 2. Configure UFW Firewall
########################################
echo "[2] Setting up UFW Firewall..."

# Reset firewall to default
sudo ufw --force reset

# Default rules
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow required services
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Limit SSH login attempts
sudo ufw limit 22/tcp

sudo ufw --force enable

echo "UFW Status:"
sudo ufw status verbose

########################################
# 3. SSH Hardening
########################################
echo "[3] Hardening SSH settings..."

SSHD="/etc/ssh/sshd_config"

# Backup original SSH config
if [ ! -f "${SSHD}.backup_member3" ]; then
    sudo cp "$SSHD" "${SSHD}.backup_member3"
fi

# Disable root login
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' $SSHD

# Disable password authentication (keys only)
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' $SSHD

# Disable empty passwords
sudo sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSHD

# Shorten login grace time
sudo sed -i 's/^#\?LoginGraceTime.*/LoginGraceTime 30/' $SSHD

# Apply changes
sudo systemctl restart ssh || sudo systemctl restart sshd

########################################
# 4. Basic Kernel Hardening (sysctl)
########################################
echo "[4] Applying kernel hardening rules..."

SYSCTL="/etc/sysctl.d/99-security.conf"

sudo tee $SYSCTL > /dev/null << 'EOF'
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
EOF

sudo sysctl --system

########################################
# 5. Secure Web Directory Permissions
########################################
echo "[5] Securing web directory..."

WEB="/var/www/group_site"

if [ -d "$WEB" ]; then
    sudo chown -R $USER:$USER "$WEB"
    sudo find "$WEB" -type d -exec chmod 755 {} \;
    sudo find "$WEB" -type f -exec chmod 644 {} \;
else
    echo "Web directory not found: $WEB"
fi

########################################
# 6. Fail2ban Configuration
########################################
echo "[6] Configuring Fail2ban..."

JAIL="/etc/fail2ban/jail.local"

sudo tee $JAIL > /dev/null << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled  = true
port     = ssh
logpath  = /var/log/auth.log
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

########################################
# 7. Automatic Security Updates
########################################
echo "[7] Enabling automatic updates..."

AUTO="/etc/apt/apt.conf.d/20auto-upgrades"

sudo tee $AUTO > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

sudo dpkg-reconfigure -f noninteractive unattended-upgrades

########################################
# 8. Generate Security Report
########################################
echo "[8] Generating security report..."

REPORT_DIR=~/webserver_lab/report
mkdir -p "$REPORT_DIR"

REPORT="$REPORT_DIR/security_report.txt"

{
echo "Security Report - Member 3"
echo "=========================="
date
echo
echo "--- Firewall Status ---"
sudo ufw status verbose
echo
echo "--- SSH Security Settings ---"
grep -E 'PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords|LoginGraceTime' $SSHD
echo
echo "--- Fail2ban Status ---"
sudo fail2ban-client status sshd 2>/dev/null || echo "Fail2ban not active"
} > "$REPORT"

echo "Report saved to $REPORT"
echo "=== MEMBER 3 COMPLETE ==="

