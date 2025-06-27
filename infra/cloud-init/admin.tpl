#!/bin/bash
# infra/cloud-init/admin.tpl  – FULL FILE
# cloud-init script for admin.axialy.ai

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
# 3 ) Expose DB credentials to PHP-FPM and the app
###############################################################################
cat >/etc/php/8.1/fpm/pool.d/99-axialy-admin-env.conf <<EOF
env[DB_HOST] = ${db_host}
env[DB_USER] = ${db_user}
env[DB_PASS] = ${db_pass}
env[DB_NAME] = ${db_name}
EOF

cat >/var/www/html/.env <<EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
EOF
chown www-data:www-data /var/www/html/.env
chmod 600 /var/www/html/.env

###############################################################################
# 4 ) Nginx virtual host  (***fixed*** – doc-root now /public)
###############################################################################
cat >/etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name admin.axialy.ai;

    # ── FIX: point Nginx at Laravel’s /public folder ──────────────
    root /var/www/html/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    # deny access to hidden files like .env, .git, etc.
    location ~ /\. {
        deny all;
    }

    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log warn;
}
CONF

nginx -t

###############################################################################
# 5 ) Kick everything
###############################################################################
systemctl restart php8.1-fpm
systemctl restart nginx
