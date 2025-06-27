/**  infra/outputs.tf  – FULL FILE  **/

/* IPv4 addresses of every droplet we spin up */
output "droplet_ips" {
  value = {
    admin = digitalocean_droplet.admin.ipv4_address
    ui    = digitalocean_droplet.ui.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
    root  = digitalocean_droplet.root.ipv4_address
  }
}

/* MySQL connection details for the Axialy Admin service */
output "admin_db_config" {
  description = "MySQL connection details for the Axialy Admin service"
  value = {
    host     = digitalocean_database_cluster.mysql.host
    user     = digitalocean_database_cluster.mysql.user
    password = digitalocean_database_cluster.mysql.password
    name     = digitalocean_database_db.admin.name
  }
  sensitive = true
}
