#cloud-config
package_update: true
packages:
  - nginx
  - php-fpm            # so PHP sites work out-of-the-box
  - unzip

write_files:
  # secrets surfaced to PHP by the legacy bootstrap you showed me
  - path: /etc/axialy_admin_env
    owner: root:root
    permissions: '0600'
    content: |
      # dropped in automatically by Terraform
      DB_HOST=${admin_db_host}
      DB_PORT=${admin_db_port}
      DB_NAME=${admin_db_name}
      DB_USER=${admin_db_user}
      DB_PASS=${admin_db_password}

  # nginx virtual-host – simple but good enough for an SPA / PHP front controller
  - path: /etc/nginx/sites-available/default
    owner: root:root
    permissions: '0644'
    content: |
      server {
        listen 80 default_server;
        root /var/www/html;
        index index.php index.html;

        server_name _;  # any host-header

        location / {
          try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
          include snippets/fastcgi-php.conf;
          fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        }
      }

runcmd:
  - systemctl enable --now nginx
  - systemctl enable --now php8.1-fpm

final_message: "cloud-init finished – ${HOSTNAME}"
