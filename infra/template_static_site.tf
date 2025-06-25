# infra/template_static_site.tf
############################################################
# Renders cloud-init once, injecting live DB credentials.
# All static-site droplets (root/ui/api/admin) share it.
############################################################

locals {
  static_site_user_data = templatefile(
    "${path.module}/cloud-init/static_site.tpl",   # ← fixed path
    {
      admin_db_host     = digitalocean_database_cluster.mysql.host
      admin_db_port     = digitalocean_database_cluster.mysql.port
      admin_db_name     = digitalocean_database_db.admin.name
      admin_db_user     = digitalocean_database_user.admin_app.name
      admin_db_password = digitalocean_database_user.admin_app.password
    }
  )
}
