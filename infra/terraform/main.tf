###############################################################################
#  Axialy Platform – Terraform MAIN
#  ---------------------------------------------------------------------------
#  • Only *resources* live here.
#  • Provider configurations and outputs have been moved to separate files
#    to avoid any duplication errors.
###############################################################################

#################################
#  SSH key (imported or created)
#################################
resource "digitalocean_ssh_key" "axialy" {
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

#################################
#  Managed MySQL cluster
#################################
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

#################################
#  Droplet running the container stack
#################################
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
