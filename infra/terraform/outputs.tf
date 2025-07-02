output "droplet_ip" {
  description = "Public IPv4 of the admin droplet"
  value       = digitalocean_droplet.admin.ipv4_address
}

output "db_host" {
  value       = digitalocean_database_cluster.axialy.host
}

output "db_port" {
  value       = digitalocean_database_cluster.axialy.port
}

output "db_username" {
  value       = digitalocean_database_user.admin_user.name
}

output "db_password" {
  value       = digitalocean_database_user.admin_user.password
  sensitive   = true
}
