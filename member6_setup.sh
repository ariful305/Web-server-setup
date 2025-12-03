#!/bin/bash
echo "=== UBUNTU APACHE AUTO SITE SETUP ==="

echo -n "Enter your site name (example: mysite.local): "
read SITENAME

SITE_DIR="/var/www/$SITENAME"

sudo mkdir -p $SITE_DIR
sudo chown -R $USER:$USER $SITE_DIR
sudo chmod -R 755 $SITE_DIR

cat <<EOF > $SITE_DIR/index.html
<h1>Apache Site Working: $SITENAME</h1>
<p>Ubuntu Auto Setup Successful!</p>
EOF

VHOST="/etc/apache2/sites-available/$SITENAME.conf"
sudo tee $VHOST > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $SITENAME
    DocumentRoot $SITE_DIR
    <Directory $SITE_DIR>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

sudo a2ensite $SITENAME.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

echo "127.0.0.1   $SITENAME" | sudo tee -a /etc/hosts

echo "Open: http://$SITENAME"
echo "=== AUTO SITE SETUP COMPLETE ==="


if [ ! -d "/var/www" ]; then
    echo "[!] /var/www does not exist. Creating it..."
    sudo mkdir -p /var/www
    sudo chmod 755 /var/www
fi


if [ -L "$HOME/www" ]; then
    echo "[1] Removing old www link..."
    rm -f "$HOME/www"
fi

echo "[2] Creating www shortcut in home directory..."
ln -s /var/www ~/www

echo "[3] Verifying link..."
ls -l ~/www

echo "=== MEMBER 6 COMPLETE: You can now access www in your Home folder ==="
