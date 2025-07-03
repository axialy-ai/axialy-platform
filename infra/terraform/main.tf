###############################################################################
#  Axialy Platform – Terraform
###############################################################################
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

###############################################################################
#  SSH key (imported or created)
###############################################################################
resource "digitalocean_ssh_key" "axialy" {
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

###############################################################################
#  Managed MySQL cluster
###############################################################################
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
}

# ── Databases (mixed-case names, per requirement) ────────────────────────────
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

# ── Users (same credentials for both DBs) ────────────────────────────────────
resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin_user"
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui_user"
}

###############################################################################
#  Droplet running the container stack
###############################################################################
resource "digitalocean_droplet" "admin" {
  name       = "axialy-admin-droplet"
  region     = var.region
  image      = "ubuntu-22-04-x64"
  size       = "s-1vcpu-1gb"
  ipv6       = true
  monitoring = true

  ssh_keys   = [digitalocean_ssh_key.axialy.id]

  user_data = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
}

###############################################################################
#  Outputs consumed by the GitHub workflow
###############################################################################
output "droplet_ip" {
  description = "Public IPv4 of the admin droplet"
  value       = digitalocean_droplet.admin.ipv4_address
}

output "db_host" {
  value = digitalocean_database_cluster.axialy.host
}

output "db_port" {
  value = digitalocean_database_cluster.axialy.port
}

output "db_username" {
  value = digitalocean_database_user.admin_user.name
}

output "db_password" {
  value     = digitalocean_database_user.admin_user.password
  sensitive = true
}
