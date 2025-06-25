# infra/template_static_site.tf
##############################

# Render the cloud-init YAML once, injecting DB creds pulled from DO resources.
locals {
  static_site_user_data = templatefile(
    "${path.module}/cloudinit/static_site.tpl",
    {
      admin_db_host     = digitalocean_database_cluster.mysql.host
      admin_db_port     = digitalocean_database_cluster.mysql.port
      admin_db_name     = digitalocean_database_db.admin.name
      admin_db_user     = digitalocean_database_user.admin_app.name
      admin_db_password = digitalocean_database_user.admin_app.password
    }
  )
}
