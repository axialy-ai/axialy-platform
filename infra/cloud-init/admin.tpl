#!/bin/bash
# infra/cloud-init/admin.tpl  – FULL FILE
# cloud-init script for the admin droplet (admin.axialy.ai)
# The placeholders ${db_host} etc. are substituted by Terraform’s
# template_file data source before the droplet is created.

set -eux

###############################################################################
# 1 ) Packages
###############################################################################
apt-get update
DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-xml \
    php8.1-curl

###############################################################################
# 2 ) Prepare web-root
###############################################################################
rm -f /var/www/html/index.nginx-debian.html || true
chown -R www-data:www-data /var/www/html

###############################################################################
# 3 ) Inject DB credentials for PHP-FPM   (env[] whitelist is mandatory)
###############################################################################
cat >/etc/php/8.1/fpm/pool.d/99-axialy-admin-env.conf <<EOF
; added by cloud-init
env[DB_HOST] = ${db_host}
env[DB_USER] = ${db_user}
env[DB_PASS] = ${db_pass}
env[DB_NAME] = ${db_name}
EOF

# Optional: also drop a .env file for CLI-use / fallbacks
cat >/var/www/html/.env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
EOF
chown www-data:www-data /var/www/html/.env
chmod 600 /var/www/html/.env

###############################################################################
# 4 ) Nginx virtual-host
###############################################################################
cat >/etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name admin.axialy.ai;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
CONF

nginx -t

###############################################################################
# 5 ) Kick everything
###############################################################################
systemctl restart nginx
systemctl restart php8.1-fpm
