########################################
# Public IPv4 addresses for each host  #
########################################
output "droplet_ips" {
  description = "Public IPv4 for every Axialy droplet"
  value       = { for k, d in digitalocean_droplet.sites : k => d.ipv4_address }
}

########################################
# Admin-app MySQL connection details   #
########################################
output "admin_db_host"     { value = digitalocean_database_cluster.mysql.host }
output "admin_db_port"     { value = digitalocean_database_cluster.mysql.port }
output "admin_db_user"     { value = digitalocean_database_user.admin_app.name }
output "admin_db_password" { value = digitalocean_database_user.admin_app.password sensitive = true }
output "admin_db_name"     { value = digitalocean_database_db.admin.name }
