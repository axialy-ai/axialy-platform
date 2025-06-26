#cloud-config
package_update: true
package_upgrade: true
packages:
  - nginx

write_files:
  - path: /etc/nginx/sites-available/default
    owner: root:root
    permissions: '0644'
    content: |
      server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        index index.html index.htm;
        # If you add HTTPS later, certbot will rewrite this file.
        server_name _;
        location / {
          try_files $uri $uri/ =404;
        }
      }

runcmd:
  # enable & start nginx
  - systemctl enable --now nginx

  # allow web traffic through Ubuntu’s firewall
  - |
    if command -v ufw >/dev/null 2>&1; then
      ufw --force allow 80/tcp
      ufw --force allow 443/tcp
      ufw --force enable
    fi
