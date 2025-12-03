#!/bin/bash
set -euo pipefail

APACHE_ERROR_LOG="/var/log/apache2/error.log"
ANOMALY_FILE="$HOME/log_anomalies.txt"
CPU_THRESHOLD=50

PURPLE="\e[35m"; RESET="\e[0m"

log() {
    printf "%b[MON]%b %s\n" "$PURPLE" "$RESET" "$*"
}

echo "=== MEMBER 4: Monitoring + Auto-Recovery ==="

log "1) Uptime and last reboot history..."
uptime
last reboot | head -5 || true

log "2) Scanning Apache error log for anomalies (404, 500, denied, error, warn)..."
if [[ -f "$APACHE_ERROR_LOG" ]]; then
    grep -Ei "404|500|denied|error|warn" "$APACHE_ERROR_LOG" | tail -n 20 > "$ANOMALY_FILE" || true
    log "Anomalies (if any) saved to: $ANOMALY_FILE"
else
    log "Apache error log not found at $APACHE_ERROR_LOG"
fi

log "3) Network latency tests (google.com and 1.1.1.1)..."
for host in "google.com" "1.1.1.1"; do
    echo "--- ping $host ---"
    ping -c 2 "$host" || echo "Ping to $host failed."
done

log "4) Checking top CPU processes..."
# Use ps with sort and head, then parse with read
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -5

# Find a single high-CPU process (ignore the header)
HIGH_LINE=$(ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | awk 'NR==2')
HIGH_CPU_PID=$(awk '{print $1}' <<< "$HIGH_LINE")
HIGH_CPU_PERCENT=$(awk '{print $4}' <<< "$HIGH_LINE")

if [[ -n "${HIGH_CPU_PERCENT:-}" ]]; then
    CPU_INT=${HIGH_CPU_PERCENT%.*}
    if (( CPU_INT > CPU_THRESHOLD )); then
        log "High CPU usage detected: PID=$HIGH_CPU_PID, CPU=$HIGH_CPU_PERCENT%"
        read -rp "Do you want to kill this process? [y/N]: " ans
        case "$ans" in
            y|Y)
                kill -9 "$HIGH_CPU_PID" && log "Killed process $HIGH_CPU_PID"
                ;;
            *)
                log "Process not killed."
                ;;
        esac
    else
        log "No process above ${CPU_THRESHOLD}% CPU."
    fi
fi

log "5) Auto-restart Apache if down..."
if ! systemctl is-active --quiet apache2; then
    log "Apache appears DOWN, attempting restart..."
    sudo systemctl restart apache2
    if systemctl is-active --quiet apache2; then
        log "Apache restarted successfully."
    else
        log "Failed to restart Apache. Check systemctl status apache2."
    fi
else
    log "Apache is running normally."
fi

echo "=== MEMBER 4: COMPLETED ==="
