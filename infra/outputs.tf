###############################################################################
# infra/outputs.tf           ⬅️  **drop-in replacement**
###############################################################################

# ─────────────────────────────────────────────────────────────────────────────
# Droplet public IPv4 addresses (used by GitHub Actions for SCP/SSH and DNS)
# ─────────────────────────────────────────────────────────────────────────────
output "droplet_ips" {
  value = {
    admin = digitalocean_droplet.admin.ipv4_address
    ui    = digitalocean_droplet.ui.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
    root  = digitalocean_droplet.root.ipv4_address
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Managed MySQL cluster connection details
#   • the GitHub workflow writes these into .env on admin.axialy.ai
#   • all are marked sensitive in the state file automatically
# ─────────────────────────────────────────────────────────────────────────────
output "mysql_host" {
  value       = digitalocean_database_cluster.mysql.host
  description = "Hostname of the DigitalOcean MySQL cluster"
}

output "mysql_port" {
  value       = digitalocean_database_cluster.mysql.port
  description = "Port of the MySQL cluster (default 25060)"
}

output "mysql_user" {
  value       = digitalocean_database_cluster.mysql.user
  description = "Auto-generated admin user for the cluster"
  sensitive   = true
}

output "mysql_password" {
  value       = digitalocean_database_cluster.mysql.password
  description = "Password for the auto-generated admin user"
  sensitive   = true
}
