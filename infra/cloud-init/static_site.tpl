#cloud-config
package_update: true
packages:
  - nginx
  - php-fpm
  - unzip

write_files:
  - path: /etc/axialy_admin_env
    owner: root:root
    permissions: "0600"
    content: |
      DB_HOST=${admin_db_host}
      DB_PORT=${admin_db_port}
      DB_NAME=${admin_db_name}
      DB_USER=${admin_db_user}
      DB_PASS=${admin_db_password}

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
        fastcgi_pass unix:$${PHP_SOCK};
      }
    }
NGINX

    systemctl enable --now nginx
    systemctl restart nginx

final_message: "cloud-init finished – $${HOSTNAME}"
