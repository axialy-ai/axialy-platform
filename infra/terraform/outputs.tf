output "droplet_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}

output "db_host" {
  value = digitalocean_database_cluster.axialy.host
}

output "db_port" {
  value = digitalocean_database_cluster.axialy.port
}
