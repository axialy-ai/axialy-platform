###############################################################################
#  infra/main.tf
###############################################################################

#########################
#  Locals
#########################

locals {
  # cloud-init shared by the front-end droplets (root, ui, api)
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
      - ufw allow 'Nginx Full' || true
  EOF

  common_tags = ["axialy"]
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

# ── Marketing / root ─────────────────────────────────────────────────────────
resource "digitalocean_droplet" "root" {
  name       = var.domain
  region     = var.region
  size       = var.droplet_size
  image      = var.droplet_image
  ssh_keys   = [var.ssh_fingerprint]
  tags       = concat(local.common_tags, ["www"])
  user_data  = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
}

# ── UI ───────────────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "ui" {
  name       = "ui.${var.domain}"
  region     = var.region
  size       = var.droplet_size
  image      = var.droplet_image
  ssh_keys   = [var.ssh_fingerprint]
  tags       = concat(local.common_tags, ["ui"])
  user_data  = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
}

# (The Admin droplet is defined in infra/admin-droplet.tf)

# ── API ──────────────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "api" {
  name       = "api.${var.domain}"
  region     = var.region
  size       = var.droplet_size
  image      = var.droplet_image
  ssh_keys   = [var.ssh_fingerprint]
  tags       = concat(local.common_tags, ["api"])
  user_data  = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
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
    digitalocean_droplet.admin.urn,  # comes from admin-droplet.tf
    digitalocean_droplet.api.urn,
    digitalocean_database_cluster.mysql.urn
  ]
}
