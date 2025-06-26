#cloud-config
package_update: true
packages:
  - nginx          # web-server
  - php-fpm        # whatever default version Ubuntu ships (8.3 today)
  - unzip

# ---------------------------------------------------------------------------
# write DB creds that the admin product’s bootstrap script will read
# ---------------------------------------------------------------------------
write_files:
  - path: /etc/axialy_admin_env
    owner: root:root
    permissions: "0600"
    content: |
      # populated by Terraform variables
      DB_HOST=${admin_db_host}
      DB_PORT=${admin_db_port}
      DB_NAME=${admin_db_name}
      DB_USER=${admin_db_user}
      DB_PASS=${admin_db_password}

# ---------------------------------------------------------------------------
# runcmd — runs once at first boot
#   • builds an nginx vhost whose fastcgi_pass matches *whatever* php-fpm
#     version the OS just installed (8.1, 8.2, 8.3 …)
#   • starts/ enables nginx   (php-fpm is already auto-enabled by apt)
# ---------------------------------------------------------------------------
runcmd:
  - |
    set -eu
    PHP_SOCK=$(ls /run/php/php*-fpm.sock | head -n1)

    cat >/etc/nginx/sites-available/default <<NGINX
    server {
      listen 80 default_server;
      root /var/www/html;
      index index.php index.html;

      server_name _;

      location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
      }

      location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
    }
NGINX

    systemctl enable --now nginx
    systemctl restart nginx

# Terraform variables are rendered now; $$ keeps \$HOSTNAME for run-time
final_message: "cloud-init finished – $${HOSTNAME}"
