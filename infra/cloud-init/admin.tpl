#!/bin/bash
# infra/cloud-init/admin.tpl  – full replacement
# cloud-init for admin.axialy.ai

set -eux

# 1 ) system packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  nginx \
  php-fpm \
  php8.1-mysql \
  php8.1-xml \
  php8.1-curl

# 2 ) clean + prepare web-root
rm -f /var/www/html/index.nginx-debian.html || true
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html

# 3 ) virtual-host (PHP first)
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
systemctl reload nginx
