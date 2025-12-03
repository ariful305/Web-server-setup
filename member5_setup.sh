#!/bin/bash
set -euo pipefail

echo "=== MEMBER 5: Backup Rotation + Remote Sync + Restore ==="

YELLOW="\e[33m"; RESET="\e[0m"
BACKUP_ROOT="$HOME/webserver_lab/backups"

log() {
    printf "%b[BKP]%b %s\n" "$YELLOW" "$RESET" "$*"
}

# Ask for sitename (trim spaces)
read -rp "Enter your site name (example: mysite.local): " raw_name
SITENAME="${raw_name//[[:space:]]/}"
if [[ -z "$SITENAME" ]]; then
    echo "Site name cannot be empty."
    exit 1
fi

WEBROOT="/var/www/$SITENAME"
BACKUP_DIR="$BACKUP_ROOT/$SITENAME"

log "Checking web root at $WEBROOT ..."
if [[ ! -d "$WEBROOT" ]]; then
    echo "[!] Web root not found: $WEBROOT"
    echo "    Make sure the site is created by the auto setup script."
    exit 1
fi

log "Ensuring backup directory $BACKUP_DIR exists ..."
mkdir -p "$BACKUP_DIR"

log "Creating timestamped backup for $SITENAME ..."
NOW_DATE=$(date +%F_%H-%M)
FILE="${SITENAME}_backup_${NOW_DATE}.tar.gz"
sudo tar -czf "$BACKUP_DIR/$FILE" "$WEBROOT"

log "Backup created: $BACKUP_DIR/$FILE"

log "Performing backup rotation (keep 7 latest)..."
cd "$BACKUP_DIR"

# mapfile + sort to get newest first
mapfile -t BACKUP_FILES < <(ls -1t *.tar.gz 2>/dev/null || true)
TOTAL=${#BACKUP_FILES[@]}
log "Total backups found: $TOTAL"

if (( TOTAL > 7 )); then
    for (( i=7; i<TOTAL; i++ )); do
        OLD="${BACKUP_FILES[$i]}"
        log "Deleting old backup: $OLD"
        rm -f "$OLD"
    done
else
    log "No old backups need to be deleted."
fi

log "Creating restore script..."
RESTORE_SCRIPT="$BACKUP_DIR/restore.sh"
cat > "$RESTORE_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail
echo "=== RESTORE SCRIPT FOR: $SITENAME ==="

BACKUP_DIR="$BACKUP_DIR"
WEBROOT="$WEBROOT"

if [[ ! -d "\$BACKUP_DIR" ]]; then
    echo "[!] Backup directory not found: \$BACKUP_DIR"
    exit 1
fi

cd "\$BACKUP_DIR"

mapfile -t FILES < <(ls -1t *.tar.gz 2>/dev/null || true)
if (( \${#FILES[@]} == 0 )); then
    echo "No backup files found in \$BACKUP_DIR"
    exit 1
fi

LATEST="\${FILES[0]}"
echo "Restoring \$LATEST to / (it contains \$WEBROOT)..."
sudo tar -xzf "\$LATEST" -C /
echo "Restore completed: \$LATEST"
EOF

chmod +x "$RESTORE_SCRIPT"
log "Restore script created at: $RESTORE_SCRIPT"

log "Searching errors in Apache logs..."
LOG_FILE="/var/log/apache2/error.log"
if [[ -f "$LOG_FILE" ]]; then
    grep -i "error" "$LOG_FILE" | tail -n 10 || echo "No recent errors found."
else
    echo "Apache error log not found at $LOG_FILE"
fi

echo "=== MEMBER 5: COMPLETED for site $SITENAME ==="
