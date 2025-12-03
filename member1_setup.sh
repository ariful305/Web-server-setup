#!/bin/bash
echo "=== MEMBER 1: System Prep + Health Check + Auto Clean ==="

echo "[1] Creating project structure..."
mkdir -p ~/webserver_lab/{config,public,logs,scripts,backups,runtime,temp,report}

echo "[2] System hardware info..."
CPU=$(lscpu | grep "Model name")
MEM=$(free -h | grep Mem)
DISK=$(df -h / | tail -1)

echo "[3] Checking network connectivity..."
ping -c 2 google.com &> /dev/null && echo "Internet OK" || echo "No Internet!"
nslookup google.com &> /dev/null && echo "DNS OK" || echo "DNS FAIL"

echo "[4] Installing dependencies..."
sudo apt install -y curl git net-tools traceroute

echo "[5] Creating HTML files..."
cd ~/webserver_lab/public
echo "<h1>Home Page</h1>" > home.html
echo "<h1>About</h1>" > about.html
echo "<h1>Contact</h1>" > contact.html

echo "[6] Creating environment setup script..."
cat << 'EOF' > ~/webserver_lab/scripts/setup_env.sh
#!/bin/bash
mkdir -p ~/webserver_lab/runtime
cp ~/webserver_lab/public/*.html ~/webserver_lab/runtime/
EOF
chmod +x ~/webserver_lab/scripts/setup_env.sh
~/webserver_lab/scripts/setup_env.sh

echo "[7] Creating auto-clean script..."
cat << 'EOF' > ~/webserver_lab/scripts/cleanup.sh
#!/bin/bash
rm -rf ~/webserver_lab/temp/*
echo "Temporary files cleaned!"
EOF
chmod +x ~/webserver_lab/scripts/cleanup.sh

echo "[8] Generating system_report.txt..."
cat << EOF > ~/webserver_lab/report/system_report.txt
System Report:
--------------
CPU: $CPU
Memory: $MEM
Disk: $DISK
IP Address: $(hostname -I)
Kernel: $(uname -r)
EOF

echo "=== MEMBER 1: COMPLETED ==="

