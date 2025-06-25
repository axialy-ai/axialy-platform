# infra/template_static_site.tf
data "template_file" "static_site" {
  template = file("${path.module}/cloudinit/static_site.tpl")
  vars = {
    admin_db_host     = digitalocean_database_cluster.mysql.host
    admin_db_port     = digitalocean_database_cluster.mysql.port
    admin_db_name     = digitalocean_database_db.admin.name
    admin_db_user     = digitalocean_database_user.admin_app.name
    admin_db_password = digitalocean_database_user.admin_app.password
  }
}
