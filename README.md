Here is a complete **GitHub-ready README.md** for your project, including all member scripts, instructions, features, how to run, architecture, and citations for the scripts.

---

# 🚀 **Ubuntu Web Server Automation – Group Project**

Automated Apache Setup, Security, Monitoring & Backup

This project contains **five Bash automation scripts** (one per group member) plus a master script to run everything together.
The goal is to fully automate **web server deployment**, **security hardening**, **monitoring**, and **backup management** on **Ubuntu Desktop**.

---

## 📁 **Project Structure**

```
├── member1_setup.sh     # Apache + SSL + Modules
├── member2_setup.sh     # Auto VirtualHost + Document Root Setup
├── member3_setup.sh     # Security, Firewall, SSH Hardening
├── member4_setup.sh     # Monitoring + Auto-Recovery
├── member5_setup.sh     # Backup, Rotation, Restore Script
├── run.sh               # Execute all scripts in sequence
```

---

# 🧩 **Member-Wise Responsibilities**

---

## **🟦 Member 1 – Apache + SSL + Modules**

✔ Installs Apache, OpenSSL

✔ Creates `/var/www/group_site`

✔ Generates a **self-signed SSL certificate**

✔ Sets up **HTTPS VirtualHost** + **HTTP→HTTPS Redirect**

✔ Enables useful modules (SSL, Rewrite, Headers, Expires)

📌 Script reference:


---

## **🟩 Member 2 – Auto Site Setup**

✔ Asks user for a site name (example: `mysite.local`)

✔ Creates `/var/www/<sitename>`

✔ Builds a complete Apache VirtualHost

✔ Disables default site & enables new site

✔ Adds site to `/etc/hosts`

✔ Creates `~/www` → `/var/www` symlink

📌 Script reference:


---

## **🟦 Member 3 – Server Security + Firewall + SSH Hardening**

✔ Sets UFW firewall rules

✔ Installs `fail2ban`, `unattended-upgrades`

✔ Hardens SSH (`PermitRootLogin no`, disables password login)

✔ Creates a full **Security Report**

📌 Script reference:


---

## **🟪 Member 4 – Monitoring + Auto-Recovery**

✔ System uptime & reboot history

✔ Apache error log anomaly detection

✔ Ping test to google.com & Cloudflare

✔ Shows top CPU processes

✔ Auto-restart Apache if down

📌 Script reference:


---

## **🟨 Member 5 – Backup, Rotation, Restore**


✔ Backup `/var/www/<sitename>` into timestamped tar.gz

✔ Keeps latest **7 backups only**

✔ Auto-generates restore script

✔ Scans Apache logs for errors

📌 Script reference:

---

# ▶️ **How to Run All Scripts Automatically**

You can run all member scripts in order using:

```bash
bash run.sh
```

This executes:

    1. Member 1 setup
    2. Member 2 site creation
    3. Member 3 security setup
    4. Member 4 monitoring
    5. Member 5 backup

📌 Script reference:


---

# 🌐 **How to Access Your Website**

After setup:

### **Apache Default SSL Site**

```
https://group.local
```

Or for Member 2's custom site:

```
http://<sitename>.local
```

Make sure the sitename is added in `/etc/hosts` (the script handles this automatically).

---

# 🔐 **Security Features**

* Firewall (UFW) enabled
* Fail2ban protection
* SSH hardening
* SSL certificate
* Error log scanning
* Auto Apache restart

---

# 🗂 **Backup & Restore**

Backups saved at:

```
~/webserver_lab/backups/<sitename>/
```

Restore using:

```bash
bash ~/webserver_lab/backups/<sitename>/restore.sh
```

---

# ⚙️ Requirements

* Ubuntu Desktop (not Ubuntu Server)
* Sudo privileges
* Internet connection

---

# 📌 **How This Project Helps**

### **Skills Learned**

* Bash scripting automation
* Web server deployment
* Security & firewall configuration
* Monitoring tools
* Automated backup strategies

### **Engineering Impact**

* Reduces human configuration errors
* Provides sustainable system automation
* Improves reliability & security
* Teaches real DevOps practices

---

# 📚 **References**

* Apache Documentation — [https://httpd.apache.org/](https://httpd.apache.org/)
* UFW Firewall — [https://wiki.ubuntu.com/UncomplicatedFirewall](https://wiki.ubuntu.com/UncomplicatedFirewall)
* Fail2ban — [https://www.fail2ban.org/](https://www.fail2ban.org/)
* OpenSSL — [https://www.openssl.org/](https://www.openssl.org/)
* Ubuntu Manpages — [https://manpages.ubuntu.com/](https://manpages.ubuntu.com/)

---

If you want, I can also:
    
✅ Add badges (build, version, license)

✅ Format for GitHub Pages

✅ Add screenshots or diagrams

✅ Create a PDF version of this README

Just tell me!
