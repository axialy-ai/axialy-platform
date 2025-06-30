###############################################################################
# infra/main.tf           ◂─ ONLY FILE UPDATED
###############################################################################

############################
# 1 ▸ Managed MySQL cluster
############################
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  region     = var.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

###############################
# 2 ▸ Admin droplet + cloud-init
###############################
locals {
  admin_cloud_init = <<EOF
#cloud-config
package_update: true
packages:
  - nginx
  - php8.1-fpm
  - php8.1-mysql
  - php8.1-cli
  - ufw

write_files:
  - path: /etc/nginx/sites-available/admin.axialy.ai
    owner: root:root
    permissions: "0644"
    content: |
      server {
          listen 80;
          listen [::]:80;
          server_name admin.axialy.ai _;
          root /var/www/html;
          index index.php index.html;
          
          location / {
              try_files \$uri \$uri/ /index.php?\$args;
          }

          location ~ \.php$ {
              include snippets/fastcgi-php.conf;
              fastcgi_pass unix:/run/php/php8.1-fpm.sock;
          }

          location ~ /\.(?!well-known) {
              deny all;
          }
      }

runcmd:
  - [bash, -c, "ln -sf /etc/nginx/sites-available/admin.axialy.ai /etc/nginx/sites-enabled/admin.axialy.ai"]
  - [bash, -c, "rm -f /etc/nginx/sites-enabled/default"]
  - [systemctl, enable, --now, php8.1-fpm]
  - [systemctl, enable, --now, nginx]
  - [bash, -c, "ufw allow 'Nginx Full' || true"]
  - [systemctl, reload, nginx]
EOF
}

resource "digitalocean_droplet" "admin" {
  name       = "admin.axialy.ai"
  region     = var.region
  size       = var.droplet_size
  image      = "ubuntu-22-04-x64"
  ssh_keys   = [var.ssh_fingerprint]
  user_data  = local.admin_cloud_init
  tags       = ["axialy", "admin"]
}

##################
# 3 ▸ Helpful outputs
##################
output "admin_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}

output "admin_db_config" {
  sensitive = true
  value = {
    host     = digitalocean_database_cluster.mysql.host
    port     = digitalocean_database_cluster.mysql.port
    user     = digitalocean_database_cluster.mysql.user
    password = digitalocean_database_cluster.mysql.password
    name     = digitalocean_database_db.admin.name
  }
}
