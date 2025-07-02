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
# ── SSH key ──────────────────────────────────────────────────────────────────
###############################################################################
resource "digitalocean_ssh_key" "axialy" {
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

###############################################################################
# ── Managed MySQL cluster + DBs + users ─────────────────────────────────────
###############################################################################
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
}

resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin_user"
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui_user"
}

###############################################################################
# ── Droplet ──────────────────────────────────────────────────────────────────
###############################################################################
resource "digitalocean_droplet" "admin" {
  name       = "axialy-admin-droplet"
  region     = var.region
  image      = "ubuntu-22-04-x64"
  size       = "s-1vcpu-1gb"
  ipv6       = true
  monitoring = true

  ssh_keys = [digitalocean_ssh_key.axialy.id]

  user_data = <<EOF
#cloud-config
package_update: true
package_upgrade: true
EOF
}
