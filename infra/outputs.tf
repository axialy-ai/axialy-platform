############################
# Droplet public addresses #
############################
output "droplet_ips" {
  description = "Public IPv4 for each Axialy droplet"
  value = {
    admin = digitalocean_droplet.admin.ipv4_address
    ui    = digitalocean_droplet.ui.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
    root  = digitalocean_droplet.root.ipv4_address
  }
}

############################
# Admin-app MySQL details  #
############################
output "admin_db_host" {
  description = "Hostname of the managed MySQL cluster"
  value       = digitalocean_database_cluster.mysql.host
}

output "admin_db_port" {
  description = "Port of the MySQL cluster"
  value       = digitalocean_database_cluster.mysql.port
}

output "admin_db_user" {
  description = "Username used by the admin application"
  value       = digitalocean_database_user.admin_app.name
}

output "admin_db_password" {
  description = "Password for the admin application DB user"
  value       = digitalocean_database_user.admin_app.password
  sensitive   = true
}

output "admin_db_name" {
  description = "Database name used by the admin application"
  value       = digitalocean_database_db.admin.name
}
