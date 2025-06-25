variable "do_region" {
  description = "DigitalOcean region slug (e.g. nyc3, sfo3, fra1)"
  type        = string
  default     = "nyc3"
}

# --------------------- 1  Database cluster ------------------------------
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-mysql"     # <- deterministic name, never a UUID
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-2gb"
  region     = var.do_region
  node_count = 1
}

# --------------------- 2  Two logical databases -------------------------
resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_ADMIN"
}

# --------------------- 3  Least-privilege service user ------------------
resource "digitalocean_database_user" "admin_app" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "axialy_admin_app"
}

# --------------------- 4  Outputs for pipelines -------------------------
output "db_cluster_name"  { value = digitalocean_database_cluster.mysql.name }
output "admin_app_user"   { value = digitalocean_database_user.admin_app.name }
output "admin_app_password" {
  value     = digitalocean_database_user.admin_app.password
  sensitive = true
}
