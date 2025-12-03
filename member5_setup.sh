#!/bin/bash
echo "=== MEMBER 5: Backup Rotation + Remote Sync + Restore ==="

# Ask which site to back up (must match the SITENAME you used in the auto setup)
echo -n "Enter your site name (example: mysite.local): "
read SITENAME

WEBROOT="/var/www/$SITENAME"

# Check that the site directory exists
if [ ! -d "$WEBROOT" ]; then
    echo "[!] Web root not found: $WEBROOT"
    echo "    Make sure the site is created by the auto setup script."
    exit 1
fi

# One backup folder per site
BACKUP_DIR="$HOME/webserver_lab/backups/$SITENAME"
mkdir -p "$BACKUP_DIR"

echo "[1] Creating timestamped backup for $SITENAME..."
FILE="${SITENAME}_backup_$(date +%F_%H-%M).tar.gz"
sudo tar -czf "$BACKUP_DIR/$FILE" "$WEBROOT"

echo "[2] Backup rotation (keep 7 latest for this site)..."
cd "$BACKUP_DIR" || exit 1
ls -t *.tar.gz 2>/dev/null | sed -e '1,7d' | xargs -r rm --

echo "[3] (Optional) Remote backup sync..."
# Uncomment and edit this line if you want remote sync:
# rsync -av "$BACKUP_DIR/" user@server_ip:/remote_backup/"$SITENAME"/

echo "[4] Creating restore script for $SITENAME..."
cat <<EOF > "$BACKUP_DIR/restore.sh"
#!/bin/bash
BACKUP_DIR="$BACKUP_DIR"
WEBROOT="$WEBROOT"

LATEST=\$(ls -t "\$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1)
if [ -z "\$LATEST" ]; then
    echo "No backup files found in \$BACKUP_DIR"
    exit 1
fi

echo "Restoring \$LATEST to / (it contains \$WEBROOT)..."
sudo tar -xzf "\$LATEST" -C /
echo "Restore completed: \$LATEST"
EOF

chmod +x "$BACKUP_DIR/restore.sh"

echo "[5] Searching errors in Apache logs..."
grep -i "error" /var/log/apache2/error.log | tail -n 10 || echo "No recent errors found."

echo "=== MEMBER 5: COMPLETED for site $SITENAME ==="
