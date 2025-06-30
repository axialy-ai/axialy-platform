#!/bin/bash
# cloud-init user-data – installs a minimal LEMP stack for admin.axialy.ai
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# ──────────────────────────────────────────────────────
# 1 ▸ install nginx + PHP-FPM + MySQL PDO driver
# ──────────────────────────────────────────────────────
apt-get update -y
apt-get install -y nginx php-fpm php-mysql

# ──────────────────────────────────────────────────────
# 2 ▸ nginx vhost (port 80 only – TLS can be added later)
# ──────────────────────────────────────────────────────
cat >/etc/nginx/sites-available/admin <<'EOF'
server {
    listen 80 default_server;
    server_name admin.axialy.ai _;
    root  /var/www/html;
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

# ──────────────────────────────────────────────────────
# 3 ▸ make sure services are enabled & started
# ──────────────────────────────────────────────────────
systemctl enable nginx php-fpm
systemctl restart nginx php-fpm
