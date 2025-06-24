###############################################################################
#  infra/main.tf – fixed (2025-06-24)
#  – Removes bad templatefile provider
#  – Uses a plain heredoc for cloud-init
###############################################################################

#########################
#  Data & locals
#########################

data "digitalocean_ssh_key" "this" {
  fingerprint = var.ssh_fingerprint
}

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
      - ufw allow 'Nginx Full' || true
  EOF

  tags_common = ["axialy"]
}

#########################
#  Project
#########################

resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "All Axialy droplets and managed services"
  purpose     = "Web Application"
  environment = "Production"
}

#########################
#  Droplets
#########################

resource "digitalocean_droplet" "root" {
  name   = var.domain
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys  = [data.digitalocean_ssh_key.this.id]
  tags      = concat(local.tags_common, ["www"])
  user_data = local.cloud_init
}

resource "digitalocean_droplet" "ui" {
  name   = "ui.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys  = [data.digitalocean_ssh_key.this.id]
  tags      = concat(local.tags_common, ["ui"])
  user_data = local.cloud_init
}

resource "digitalocean_droplet" "admin" {
  name   = "admin.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys  = [data.digitalocean_ssh_key.this.id]
  tags      = concat(local.tags_common, ["admin"])
  user_data = local.cloud_init
}

resource "digitalocean_droplet" "api" {
  name   = "api.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys  = [data.digitalocean_ssh_key.this.id]
  tags      = concat(local.tags_common, ["api"])
  user_data = local.cloud_init
}

#########################
#  Managed MySQL cluster
#########################

resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
  project_id = digitalocean_project.axialy.id
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

#########################
#  Attach everything to the project
#########################

resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.root.urn,
    digitalocean_droplet.ui.urn,
    digitalocean_droplet.admin.urn,
    digitalocean_droplet.api.urn,
    digitalocean_database_cluster.mysql.urn
  ]
}
