###############################################################################
# infra/main.tf
###############################################################################

#########################
#  Locals (unchanged)
#########################

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
      - ufw allow 'Nginx Full' || true
      - rm -f /var/www/html/index.nginx-debian.html || true
  EOF

  common_tags = ["axialy"]
}

#########################
#  Project (unchanged)
#########################

resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "All Axialy droplets and managed services"
  purpose     = "Web Application"
  environment = "Production"
}

#########################
#  Database cluster & users (already present in cluster.tf)
#########################
#  - digitalocean_database_cluster.mysql
#  - digitalocean_database_db.admin
#  - digitalocean_database_user.admin_app
#  (left exactly as you have them)

#########################
#  Droplets
#########################

# ── Marketing / root ─────────────────────────────────────────────────────────
resource "digitalocean_droplet" "root" {
  name      = var.domain
  region    = var.region
  size      = var.droplet_size
  image     = var.droplet_image
  ssh_keys  = [var.ssh_fingerprint]
  tags      = concat(local.common_tags, ["www"])
  user_data = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
}

# ── UI ───────────────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "ui" {
  name      = "ui.${var.domain}"
  region    = var.region
  size      = var.droplet_size
  image     = var.droplet_image
  ssh_keys  = [var.ssh_fingerprint]
  tags      = concat(local.common_tags, ["ui"])
  user_data = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
}

# ── ADMIN ────────────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "admin" {
  name      = "admin.${var.domain}"
  region    = var.region
  size      = var.droplet_size
  image     = var.droplet_image
  ssh_keys  = [var.ssh_fingerprint]
  tags      = concat(local.common_tags, ["admin"])

  # Render cloud-init with live DB credentials
  user_data = templatefile(
    "${path.module}/cloud-init/admin.tpl",
    {
      db_host = digitalocean_database_cluster.mysql.host
      db_port = digitalocean_database_cluster.mysql.port
      db_name = digitalocean_database_db.admin.name
      db_user = digitalocean_database_user.admin_app.name
      db_pass = digitalocean_database_user.admin_app.password
    }
  )
}

# ── API ──────────────────────────────────────────────────────────────────────
resource "digitalocean_droplet" "api" {
  name      = "api.${var.domain}"
  region    = var.region
  size      = var.droplet_size
  image     = var.droplet_image
  ssh_keys  = [var.ssh_fingerprint]
  tags      = concat(local.common_tags, ["api"])
  user_data = local.cloud_init

  lifecycle { ignore_changes = [user_data] }
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
