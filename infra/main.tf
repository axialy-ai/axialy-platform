terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.53.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# ------------------------------------------------------------------------
# Axialy project (already exists – import on first run)
# ------------------------------------------------------------------------
resource "digitalocean_project" "axialy" {
  name        = "Axialy Platform"
  description = "Everything related to Axialy"
  purpose     = "Web Application"
  environment = "Production"
}

# ------------------------------------------------------------------------
# MySQL cluster (admin + ui databases)
# ------------------------------------------------------------------------
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "sfo3"
  node_count = 1
}

resource "digitalocean_database_db" "admin" {
  name       = "Axialy_Admin"
  cluster_id = digitalocean_database_cluster.mysql.id
}

resource "digitalocean_database_db" "ui" {
  name       = "Axialy_UI"
  cluster_id = digitalocean_database_cluster.mysql.id
}

# ------------------------------------------------------------------------
# Admin droplet – cloud-init installs nginx + PHP
# ------------------------------------------------------------------------
resource "digitalocean_droplet" "admin" {
  name              = "admin.axialy.ai"
  region            = "sfo3"
  size              = "s-1vcpu-1gb"
  image             = "ubuntu-22-04-x64"
  ssh_keys          = [var.ssh_fingerprint]
  tags              = ["axialy", "admin"]
  user_data         = file("${path.module}/user_data/admin_lemp.sh")
}

# Attach droplet & DB to the project (so they’re grouped in DO console)
resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.admin.urn,
    digitalocean_database_cluster.mysql.urn
  ]
}

# Public IP of the admin droplet
output "admin_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}
