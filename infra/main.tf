########################################
# Axialy DigitalOcean Infrastructure
########################################
locals {
  region = "sfo3"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  # bootstrap script for droplets that should expose a static site
  nginx_cloud_init = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    ufw allow 'Nginx Full' || true
    systemctl enable --now nginx
  EOF
}

########################################
# Project
########################################
resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "Project that hosts the Axialy platform"
  purpose     = "Web Application"
  environment = "Production"
}

########################################
# Droplets
########################################
resource "digitalocean_droplet" "admin" {
  name       = "admin.axialy.ai"
  region     = local.region
  size       = local.size
  image      = local.image
  tags       = ["axialy", "admin"]
  user_data  = local.nginx_cloud_init
  ssh_keys   = [var.ssh_fingerprint]
}

resource "digitalocean_droplet" "ui" {
  name       = "ui.axialy.ai"
  region     = local.region
  size       = local.size
  image      = local.image
  tags       = ["axialy", "ui"]
  user_data  = local.nginx_cloud_init
  ssh_keys   = [var.ssh_fingerprint]
}

# ------------  API droplet ------------
# - no cloud-init script here – we want YOUR build
#   (deploy-api.yml will rsync the files)
resource "digitalocean_droplet" "api" {
  name       = "api.axialy.ai"
  region     = local.region
  size       = local.size
  image      = local.image
  tags       = ["axialy", "api"]
  ssh_keys   = [var.ssh_fingerprint]
}

resource "digitalocean_droplet" "root" {
  name       = "axialy.ai"
  region     = local.region
  size       = local.size
  image      = local.image
  tags       = ["axialy", "www"]
  user_data  = local.nginx_cloud_init
  ssh_keys   = [var.ssh_fingerprint]
}

########################################
# Managed MySQL (unchanged)
########################################
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  region     = local.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
  project_id = digitalocean_project.axialy.id
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

########################################
# Attach resources to the project
########################################
resource "digitalocean_project_resources" "attach" {
  project = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.admin.urn,
    digitalocean_droplet.ui.urn,
    digitalocean_droplet.api.urn,
    digitalocean_droplet.root.urn,
  ]
}
