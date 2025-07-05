###############################################################################
#  Droplet
###############################################################################
output "droplet_ip" {
  value = digitalocean_droplet.admin.ipv4_address
}

###############################################################################
#  Admin DB
###############################################################################
output "admin_db_host" {
  value = digitalocean_database_cluster.axialy.host
}

output "admin_db_port" {
  value = digitalocean_database_cluster.axialy.port
}

output "admin_db_username" {
  value = digitalocean_database_user.admin_user.name
}

output "admin_db_password" {
  value     = digitalocean_database_user.admin_user.password
  sensitive = true
}

###############################################################################
#  UI DB
###############################################################################
output "ui_db_host" {
  value = digitalocean_database_cluster.axialy.host
}

output "ui_db_port" {
  value = digitalocean_database_cluster.axialy.port
}

output "ui_db_username" {
  value = digitalocean_database_user.ui_user.name
}

output "ui_db_password" {
  value     = digitalocean_database_user.ui_user.password
  sensitive = true
}
