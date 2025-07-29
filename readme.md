# WordPress Auto-Deployment with LAMP, SSL, Redis, and Cloudflare

This project includes a Bash script for fully automating the deployment of a secure, optimized WordPress website on an Ubuntu VPS.

---

## 🚀 Features

- Full LAMP stack installation (Apache, MySQL, PHP)
- WordPress auto-install with WP-CLI
- MySQL DB/user setup
- Apache virtual host configuration
- SSL certificate installation via Certbot (Let's Encrypt)
- Redis object caching setup
- Theme and plugin installation
- Optional Cloudflare DNS configuration
- `.env`-based configuration for security and reusability

---

## 🧩 Requirements

- Ubuntu 20.04 or 22.04 VPS
- Domain name pointed to the server IP
- `sudo` privileges

---

## 🔐 Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/wp-auto-deploy.git
cd wp-auto-deploy
```

### 2. Create a `.env` file

```bash
cp .env.example .env
nano .env
```

### 3. Update `.env` with your configuration

```env
DOMAIN="yourdomain.com"
EMAIL="admin@yourdomain.com"
DB_NAME="your_db"
DB_USER="your_user"
DB_PASS="your_password"
WEB_DIR="/var/www/html/yourdomain.com"
SITE_TITLE="My WordPress Site"
WP_ADMIN_USER="admin"
WP_ADMIN_PASS="StrongPassword123"
WP_ADMIN_EMAIL="admin@yourdomain.com"
THEME_SLUG="astra"
PLUGINS=("all-in-one-wp-migration" "wordfence" "elementor")
USE_CLOUDFLARE=true
CLOUDFLARE_TOKEN="your_cloudflare_api_token"
CLOUDFLARE_ZONE_ID="your_zone_id"
```

---

## ▶️ Usage

### Make the script executable:

```bash
chmod +x deploy.sh
```

### Run the script:

```bash
./deploy.sh
```

---

## 🛡️ Security Notes

- Always use strong passwords and unique DB credentials
- Make sure your `.env` file is excluded from version control (included in `.gitignore`)

---

## 🌐 Cloudflare Setup (Optional)

- Create a token from [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens) with **Zone\*\***:DNS\***\* Edit** permissions
- Set `USE_CLOUDFLARE=true` and provide your `CLOUDFLARE_TOKEN` and `CLOUDFLARE_ZONE_ID` in the `.env`

---

## 🧪 Future Enhancements

- GitHub Actions CI/CD deployment
- Slack/Telegram deployment notifications
- Support for NGINX and Let's Encrypt wildcard certs
- WP Multisite support

---

## 📄 License

MIT

---

Made with ❤️ by AKINADE AYODEJI
