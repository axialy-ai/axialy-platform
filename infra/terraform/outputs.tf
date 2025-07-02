###############################################################################
# Outputs consumed by the GitHub Actions workflow
###############################################################################

output "droplet_ip" {
  description = "Public IPv4 of the Axialy Admin droplet"
  value       = digitalocean_droplet.admin.ipv4_address
}

output "db_host" {
  description = "Hostname of the DigitalOcean DB cluster"
  value       = digitalocean_database_cluster.axialy.host
}

output "db_port" {
  description = "Port used by the DB cluster"
  value       = digitalocean_database_cluster.axialy.port
}

# ── NEW ──────────────────────────────────────────────────────────────────────
# These are deliberately *not* marked sensitive so the workflow can read them.
# They are masked in the workflow logs right after we read them.
output "db_username" {
  description = "Username for the primary DB user (doadmin)"
  value       = digitalocean_database_cluster.axialy.user
}

output "db_password" {
  description = "Password for the primary DB user"
  value       = digitalocean_database_cluster.axialy.password
}
