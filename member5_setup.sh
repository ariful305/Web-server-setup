#!/bin/bash
echo "=== MEMBER 5: Backup Rotation + Remote Sync + Restore ==="

BACKUP_DIR=~/webserver_lab/backups
mkdir -p $BACKUP_DIR

echo "[1] Creating timestamped backup..."
FILE="backup_$(date +%F_%H-%M).tar.gz"
sudo tar -czf $BACKUP_DIR/$FILE /var/www/group_site/

echo "[2] Backup rotation (keep 7 latest)..."
cd $BACKUP_DIR
ls -t | sed -e '1,7d' | xargs -r rm

echo "[3] (Optional) Remote backup sync..."
# rsync -av $BACKUP_DIR/ user@server_ip:/remote_backup/

echo "[4] Creating restore script..."
cat <<EOF > $BACKUP_DIR/restore.sh
#!/bin/bash
LATEST=\$(ls -t $BACKUP_DIR | head -1)
sudo tar -xzf $BACKUP_DIR/\$LATEST -C /
echo "Restore completed: \$LATEST"
EOF
chmod +x $BACKUP_DIR/restore.sh

echo "[5] Searching errors in logs..."
grep -i "error" /var/log/apache2/error.log | tail -n 10

echo "=== MEMBER 5: COMPLETED ==="

