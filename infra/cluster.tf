###############################################################################
# infra/cluster.tf  – MySQL Managed Cluster
###############################################################################

variable "region" {}
variable "db_node_size" { default = "db-s-1vcpu-1gb" }

# ── Cluster ──────────────────────────────────────────────────────────────────
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-mysql"    # <-- referenced in workflow
  engine     = "mysql"
  version    = "8"
  size       = var.db_node_size
  region     = var.region
  node_count = 1
}

# ── Databases ────────────────────────────────────────────────────────────────
resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

# ── Application-user for the Admin product ──────────────────────────────────
resource "digitalocean_database_user" "admin_app" {
  cluster_id          = digitalocean_database_cluster.mysql.id
  name                = "axialy_admin_app"
  mysql_auth_plugin   = "mysql_native_password"
}

# expose the password for workflows (marked sensitive)
output "admin_db_password" {
  value     = digitalocean_database_user.admin_app.password
  sensitive = true
}
