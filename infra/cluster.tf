###############################################################################
# infra/cluster.tf  – Managed MySQL cluster + DBs + user
###############################################################################

# ─────────────── Cluster ────────────────────────────────────────────────────
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-mysql"      # must match workflow
  engine     = "mysql"
  version    = "8"
  size       = var.db_node_size    # defined in variables.tf
  region     = var.region
  node_count = 1
}

# ─────────────── Databases ─────────────────────────────────────────────────
resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

# ─────────────── Application user for the Admin product ───────────────────
resource "digitalocean_database_user" "admin_app" {
  cluster_id        = digitalocean_database_cluster.mysql.id
  name              = "axialy_admin_app"
  mysql_auth_plugin = "mysql_native_password"
}
