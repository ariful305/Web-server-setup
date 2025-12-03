#!/bin/bash
echo "=== MEMBER 2: Apache + SSL + Modules ==="

echo "[1] Installing Apache..."
sudo apt update
sudo apt install -y apache2 apache2-utils openssl

echo "[2] Adding hostname to /etc/hosts..."
echo "127.0.0.1 group.local" | sudo tee -a /etc/hosts

echo "[3] Enabling Apache modules..."
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod expires

echo "[4] Creating SSL certificate..."
sudo mkdir -p /etc/apache2/ssl
sudo openssl req -x509 -nodes -days 365 \
    -subj "/CN=group.local" \
    -newkey rsa:2048 \
    -keyout /etc/apache2/ssl/group.key \
    -out /etc/apache2/ssl/group.crt

echo "[5] Creating secure HTTPS virtual host..."
sudo tee /etc/apache2/sites-available/group_ssl.conf > /dev/null << EOF
<VirtualHost *:443>
    ServerName group.local
    DocumentRoot /var/www/group_site

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/group.crt
    SSLCertificateKeyFile /etc/apache2/ssl/group.key

    <Directory /var/www/group_site>
        AllowOverride All
    </Directory>

    Header always set X-Frame-Options "DENY"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Strict-Transport-Security "max-age=63072000"

    ErrorLog \${APACHE_LOG_DIR}/ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF

sudo a2ensite group_ssl.conf

echo "[6] Redirect HTTP -> HTTPS..."
sudo tee /etc/apache2/sites-available/redirect_http.conf > /dev/null << EOF
<VirtualHost *:80>
    ServerName group.local
    Redirect / https://group.local/
</VirtualHost>
EOF

sudo a2ensite redirect_http.conf

echo "[7] Restarting Apache after config test..."
sudo apachectl configtest && sudo systemctl restart apache2

echo "=== MEMBER 2: COMPLETED ==="

