#!/bin/bash
set -euo pipefail

RED="\e[31m"; GREEN="\e[32m"; CYAN="\e[36m"; RESET="\e[0m"

log() {
    printf "%b[INFO]%b %s\n" "$CYAN" "$RESET" "$*"
}

ask_sitename() {
    local name
    read -rp "Enter your site name (example: mysite.local): " name
    # Trim spaces
    SITENAME="${name//[[:space:]]/}"
    if [[ -z "$SITENAME" ]]; then
        echo -e "${RED}Site name cannot be empty.${RESET}"
        exit 1
    fi
}

echo "=== UBUNTU APACHE AUTO SITE SETUP (MEMBER 2) ==="
ask_sitename

SITE_DIR="/var/www/$SITENAME"
VHOST="/etc/apache2/sites-available/$SITENAME.conf"

log "Creating site directory at $SITE_DIR ..."
sudo mkdir -p "$SITE_DIR"
sudo chown -R "$USER:$USER" "$SITE_DIR"
sudo chmod -R 755 "$SITE_DIR"

log "Writing default index.html ..."
cat > "$SITE_DIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$SITENAME</title>
</head>
<body>
    <h1>Apache Site Working: $SITENAME</h1>
    <p>Ubuntu Auto Setup Successful!</p>
</body>
</html>
EOF

log "Creating VirtualHost config at $VHOST ..."
sudo tee "$VHOST" >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $SITENAME
    DocumentRoot $SITE_DIR

    <Directory $SITE_DIR>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${SITENAME}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SITENAME}_access.log combined
</VirtualHost>
EOF

log "Enabling new site and disabling default ..."
sudo a2ensite "$SITENAME.conf" >/dev/null
sudo a2dissite 000-default.conf >/dev/null || true
sudo systemctl reload apache2

log "Adding $SITENAME to /etc/hosts if needed..."
if ! grep -q " $SITENAME" /etc/hosts; then
    echo "127.0.0.1   $SITENAME" | sudo tee -a /etc/hosts >/dev/null
fi

# Ensure /var/www exists and ~/www points to it
log "Ensuring /var/www exists ..."
if [[ ! -d "/var/www" ]]; then
    sudo mkdir -p /var/www
    sudo chmod 755 /var/www
fi

log "Managing ~/www symlink ..."
if [[ -L "$HOME/www" || -e "$HOME/www" ]]; then
    rm -rf "$HOME/www"
fi
ln -s /var/www "$HOME/www"

log "Verifying ~/www link ..."
ls -ld "$HOME/www"

echo -e "${GREEN}Open: http://$SITENAME${RESET}"
echo "=== MEMBER 2 COMPLETE: You can now access www in your Home folder ==="
