output "droplet_ips" {
  value = {
    admin = digitalocean_droplet.admin.ipv4_address
    ui    = digitalocean_droplet.ui.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
    www   = digitalocean_droplet.www.ipv4_address   # new IP output
  }
}

output "mysql_connection" {
  value     = digitalocean_database_cluster.mysql.uri
  sensitive = true
}
