#!/bin/bash

# === LOAD CONFIG FROM .env FILE ===
source .env

# === COLORS ===
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# === SYSTEM UPDATE & LAMP INSTALLATION ===
echo -e "${GREEN}Updating and installing LAMP stack...${NC}"
sudo apt update -y && sudo apt upgrade -y
sudo apt install apache2 mysql-server php php-mysql libapache2-mod-php php-cli unzip curl wget redis-server php-redis jq -y
sudo a2enmod rewrite
sudo systemctl restart apache2
sudo systemctl enable redis-server

# === CREATE MYSQL DATABASE ===
echo -e "${GREEN}Creating MySQL database and user...${NC}"
sudo mysql <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# === SETUP WEB DIRECTORY ===
echo -e "${GREEN}Setting up web directory...${NC}"
sudo mkdir -p $WEB_DIR
sudo chown -R www-data:www-data $WEB_DIR
sudo chmod -R 755 $WEB_DIR

# === DOWNLOAD & INSTALL WORDPRESS ===
echo -e "${GREEN}Downloading WordPress...${NC}"
cd /tmp && wget https://wordpress.org/latest.zip && unzip latest.zip
sudo mv wordpress/* $WEB_DIR
rm -rf wordpress latest.zip

# === CONFIGURE wp-config.php ===
cp $WEB_DIR/wp-config-sample.php $WEB_DIR/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $WEB_DIR/wp-config.php
sed -i "s/username_here/$DB_USER/" $WEB_DIR/wp-config.php
sed -i "s/password_here/$DB_PASS/" $WEB_DIR/wp-config.php

# === APACHE VIRTUAL HOST ===
echo -e "${GREEN}Configuring Apache virtual host...${NC}"
VHOST="/etc/apache2/sites-available/$DOMAIN.conf"
sudo bash -c "cat > $VHOST" <<EOL
<VirtualHost *:80>
    ServerAdmin $EMAIL
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $WEB_DIR
    <Directory $WEB_DIR>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOL

sudo a2ensite $DOMAIN.conf
sudo systemctl reload apache2

# === WP-CLI INSTALLATION ===
echo -e "${GREEN}Installing WP-CLI...${NC}"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# === WORDPRESS CORE INSTALLATION ===
echo -e "${GREEN}Installing WordPress core...${NC}"
cd $WEB_DIR
sudo -u www-data wp core install --url="https://$DOMAIN" \
  --title="$SITE_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASS" \
  --admin_email="$WP_ADMIN_EMAIL"

# === THEME INSTALLATION ===
echo -e "${GREEN}Installing theme $THEME_SLUG...${NC}"
sudo -u www-data wp theme install $THEME_SLUG --activate

# === PLUGIN INSTALLATION ===
echo -e "${GREEN}Installing plugins...${NC}"
for plugin in ${PLUGINS[@]}; do
    sudo -u www-data wp plugin install "$plugin" --activate
done

# === ENABLE REDIS CACHE ===
echo -e "${GREEN}Enabling Redis cache...${NC}"
sudo -u www-data wp plugin install redis-cache --activate
sudo -u www-data wp redis enable

# === SSL CERTIFICATE INSTALLATION ===
echo -e "${GREEN}Installing SSL via Certbot...${NC}"
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache --non-interactive --agree-tos \
  -m $EMAIL -d $DOMAIN -d www.$DOMAIN

# === CLOUDFLARE DNS CONFIGURATION (OPTIONAL) ===
if [ "$USE_CLOUDFLARE" = true ]; then
    echo -e "${GREEN}Setting up Cloudflare DNS...${NC}"
    VPS_IP=$(curl -s http://ipv4.icanhazip.com)
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{
            "type":"A",
            "name":"'"$DOMAIN"'",
            "content":"'"$VPS_IP"'",
            "ttl":120,
            "proxied":false
        }' | jq
fi

# === FINAL PERMISSIONS FIX ===
echo -e "${GREEN}Fixing permissions...${NC}"
sudo chown -R www-data:www-data $WEB_DIR
sudo find $WEB_DIR -type d -exec chmod 755 {} \;
sudo find $WEB_DIR -type f -exec chmod 644 {} \;

echo -e "${GREEN}✅ WordPress setup completed: https://$DOMAIN${NC}"
