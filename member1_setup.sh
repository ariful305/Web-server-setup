#!/bin/bash
set -euo pipefail

SITENAME="group.local"
DOCROOT="/var/www/group_site"
SSL_DIR="/etc/ssl/group_lab"
APACHE_SSL_CONF="/etc/apache2/sites-available/${SITENAME}_ssl.conf"
APACHE_REDIRECT_CONF="/etc/apache2/sites-available/redirect_http.conf"

# --- Colors ---
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; RESET="\e[0m"

log() {
    local level="$1"; shift
    printf "%b[%s]%b %s\n" "$YELLOW" "$level" "$RESET" "$*"
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        log "INFO" "Some steps need sudo; you may be prompted for password."
    fi
}

trap 'log "INFO" "MEMBER 1 script finished (status $?)."' EXIT

echo "=== MEMBER 1: Apache + SSL + Modules ==="
require_root

log "STEP" "Installing Apache and OpenSSL..."
sudo apt update -y
sudo apt install -y apache2 apache2-utils openssl

log "STEP" "Adding hostname to /etc/hosts if missing..."
if ! grep -q " ${SITENAME}" /etc/hosts; then
    echo "127.0.0.1   ${SITENAME}" | sudo tee -a /etc/hosts >/dev/null
else
    log "INFO" "${SITENAME} already present in /etc/hosts"
fi

log "STEP" "Enabling useful Apache modules..."
MODULES=(rewrite ssl headers expires)
for m in "${MODULES[@]}"; do
    sudo a2enmod "$m" >/dev/null 2>&1 || true
done

log "STEP" "Creating document root at $DOCROOT ..."
sudo mkdir -p "$DOCROOT"
sudo chown -R "$USER:$USER" "$DOCROOT"
sudo chmod -R 755 "$DOCROOT"

cat <<EOF | sudo tee "$DOCROOT/index.html" >/dev/null
<h1>Group Site over HTTPS</h1>
<p>If you see this page over <strong>https://${SITENAME}</strong>, SSL is working!</p>
EOF

log "STEP" "Creating self-signed SSL certificate..."
sudo mkdir -p "$SSL_DIR"
CRT="${SSL_DIR}/${SITENAME}.crt"
KEY="${SSL_DIR}/${SITENAME}.key"

if [[ ! -f "$CRT" || ! -f "$KEY" ]]; then
    sudo openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY" \
        -out "$CRT" \
        -subj "/CN=${SITENAME}/O=GroupLab/OU=LabProject"
else
    log "INFO" "SSL files already exist, reusing them."
fi

log "STEP" "Creating HTTPS virtual host config..."
sudo tee "$APACHE_SSL_CONF" >/dev/null <<EOF
<VirtualHost *:443>
    ServerName ${SITENAME}
    DocumentRoot ${DOCROOT}

    SSLEngine on
    SSLCertificateFile ${CRT}
    SSLCertificateKeyFile ${KEY}

    <Directory ${DOCROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ErrorLog \${APACHE_LOG_DIR}/${SITENAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SITENAME}_access.log combined
</VirtualHost>
EOF

log "STEP" "Creating HTTP → HTTPS redirect config..."
sudo tee "$APACHE_REDIRECT_CONF" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName ${SITENAME}
    Redirect / https://${SITENAME}/
</VirtualHost>
EOF

log "STEP" "Enabling SSL site and redirect..."
sudo a2ensite "$(basename "$APACHE_SSL_CONF")" >/dev/null
sudo a2ensite "$(basename "$APACHE_REDIRECT_CONF")" >/dev/null
sudo a2dissite 000-default.conf >/dev/null || true

log "STEP" "Testing Apache config and restarting..."
if sudo apachectl configtest; then
    sudo systemctl restart apache2
    log "OK" "Apache restarted successfully."
else
    log "ERROR" "Apache config test failed. Check above errors."
fi

echo -e "${GREEN}Open: https://${SITENAME}${RESET}"
echo "=== MEMBER 1: COMPLETED ==="
