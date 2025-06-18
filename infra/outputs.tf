output "droplet_ips" {
  value = {
    ui    = digitalocean_droplet.ui.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
    admin = digitalocean_droplet.admin.ipv4_address
  }
}

output "mysql_connection" {
  value = digitalocean_database_cluster.mysql.host
}

