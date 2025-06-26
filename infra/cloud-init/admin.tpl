#!/bin/bash
# cloud-init script for admin.axialy.ai
set -eux

# 1. base packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nginx php-fpm

# 2. rub out the stock splash screen so NGINX never shows it
rm -f /var/www/html/index.nginx-debian.html

# 3. minimal virtual-host that prefers PHP
cat >/etc/nginx/sites-available/default <<'CONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name admin.axialy.ai;

    root /var/www/html;
    index index.php index.html;   # PHP first

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;   # Ubuntu 22.04 socket
    }

    location ~ /\.ht {
        deny all;
    }
}
CONF

nginx -t
systemctl reload nginx
