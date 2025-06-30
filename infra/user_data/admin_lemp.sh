#!/usr/bin/env bash
# ─ Cloud-init: very small LEMP stack for admin.axialy.ai ─
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx php-fpm php-mysql

cat >/etc/nginx/sites-available/admin <<'EOF'
server {
    listen 80 default_server;
    server_name admin.axialy.ai _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF
ln -sf /etc/nginx/sites-available/admin /etc/nginx/sites-enabled/admin
rm -f /etc/nginx/sites-enabled/default

systemctl enable nginx php-fpm
systemctl restart nginx php-fpm
