###############################################################################
#  Authoritative, per-environment droplet set
#  – 4 hosts total:  root / ui / api / admin
#  – admin gets DB-aware cloud-init; all others share the static-site build
###############################################################################

locals {
  droplet_names = ["root", "ui", "api", "admin"]
  image         = var.droplet_image          # defined in variables.tf
}

# ------------- DROPLETS ------------------------------------------------------
resource "digitalocean_droplet" "sites" {
  for_each = toset(local.droplet_names)

  # apex domain for “root”, sub-domains for the rest
  name   = each.key == "root" ? var.domain : "${each.key}.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = local.image
  ssh_keys = [var.ssh_fingerprint]

  ipv6              = false
  monitoring        = false
  backups           = false
  graceful_shutdown = true

  # ─── cloud-init ────────────────────────────────────────────────────────────
  user_data = each.key == "admin"
    ? templatefile("${path.module}/cloud-init/admin.tpl", {
        db_host = digitalocean_database_cluster.mysql.host
        db_port = digitalocean_database_cluster.mysql.port
        db_name = digitalocean_database_db.admin.name
        db_user = digitalocean_database_user.admin_app.name
        db_pass = digitalocean_database_user.admin_app.password
      })
    : local.static_site_user_data    # defined in template_static_site.tf

  tags = ["axialy", each.key]
}

# ------------- ATTACH ALL RESOURCES TO THE PROJECT --------------------------
resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [for d in digitalocean_droplet.sites : d.urn]
}
