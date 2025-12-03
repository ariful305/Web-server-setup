#!/bin/bash
echo "=== MEMBER 4: Monitoring + Auto-Recovery ==="

echo "[1] Uptime and reboot history..."
uptime
last reboot | head -5

echo "[2] Log anomaly detector (404, 500, error)..."
grep -Ei "404|500|denied|error|warn" /var/log/apache2/error.log | tail -n 20 > log_anomalies.txt

echo "[3] Network latency test..."
ping -c 2 google.com
ping -c 2 1.1.1.1

echo "[4] Kill high CPU processes..."
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -5
HIGH_CPU=$(ps -eo pid,%cpu --sort=-%cpu | awk 'NR==2 {print $1}')

if (( $(ps -p $HIGH_CPU -o %cpu= | awk '{print int($1)}') > 80 )); then
    kill -9 $HIGH_CPU
    echo "Killed high CPU process: $HIGH_CPU"
fi

echo "[5] Auto-restart Apache if down..."
if ! systemctl is-active --quiet apache2; then
    echo "Apache down! Restarting..."
    sudo systemctl restart apache2
else
    echo "Apache is running normally."
fi

echo "=== MEMBER 4: COMPLETED ==="

