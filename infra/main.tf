###############################################################################
# 1. Managed MySQL cluster  (Axialy_Admin  +  Axialy_UI)
###############################################################################
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

###############################################################################
# 2. Admin droplet  – ready for rsync-based deployments
###############################################################################
locals {
  admin_cloud_init = <<EOF
#cloud-config
package_update: true
packages:
  - nginx
  - php8.1-fpm
  - php8.1-mysql
  - ufw

runcmd:
  - systemctl enable --now nginx
  - systemctl enable --now php8.1-fpm
  - ufw allow 'Nginx Full' || true
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

###############################################################################
# 3. Handy outputs
###############################################################################
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
