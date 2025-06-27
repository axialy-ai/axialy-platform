#!/bin/bash
# infra/cloud-init/admin.tpl   – cloud-init for admin.axialy.ai
# (drop-in replacement – fully automated, no manual post-steps)

set -eux

###############################################################################
# 1) Packages
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
# 2) Prepare web-root
###############################################################################
rm -f /var/www/html/index.nginx-debian.html || true
chown -R www-data:www-data /var/www/html

###############################################################################
# 3) Expose DB credentials to PHP-FPM **and** the app
###############################################################################
cat >/etc/php/8.1/fpm/pool.d/99-axialy-admin-env.conf <<EOF
env[DB_HOST]      = ${db_host}
env[DB_PORT]      = 3306
env[DB_NAME]      = ${db_name}
env[DB_USER]      = ${db_user}
env[DB_PASSWORD]  = ${db_pass}
EOF

cat >/var/www/html/.env <<EOF
DB_HOST=${db_host}
DB_PORT=3306
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_pass}
EOF
chown www-data:www-data /var/www/html/.env
chmod 600 /var/www/html/.env

###############################################################################
# 4) Nginx virtual host – **doc-root = /var/www/html**
###############################################################################
cat >/etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name admin.axialy.ai _;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    # Static assets – cache forever
    location ~* \.(?:js|css|png|jpe?g|gif|ico|svg)$ {
        try_files $uri =404;
        expires max;
        access_log off;
        log_not_found off;
    }

    # Block hidden files (.env, .git, …)
    location ~ /\.(?!well-known).* {
        deny all;
    }

    access_log  /var/log/nginx/access.log;
    error_log   /var/log/nginx/error.log warn;
}
CONF

nginx -t

###############################################################################
# 5) Kick services
###############################################################################
systemctl restart php8.1-fpm
systemctl restart nginx
