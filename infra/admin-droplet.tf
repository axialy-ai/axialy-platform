###############################################################################
# Cloud-init template rendered with DB credentials
###############################################################################
data "template_file" "admin_cloud_init" {
  template = file("${path.module}/templates/admin_cloud_init.yml.tmpl")

  vars = {
    db_host = digitalocean_database_cluster.mysql.host
    db_port = digitalocean_database_cluster.mysql.port   # ← new
    db_user = digitalocean_database_cluster.mysql.user
    db_pass = digitalocean_database_cluster.mysql.password
    db_name = digitalocean_database_db.admin.name
  }
}

###############################################################################
# Droplet for admin.axialy.ai
###############################################################################
resource "digitalocean_droplet" "admin" {
  name         = "admin.axialy.ai"
  region       = "sfo3"
  size         = "s-1vcpu-1gb"
  image        = "ubuntu-22-04-x64"

  ssh_keys     = [var.ssh_fingerprint]
  tags         = ["admin", "axialy"]
  monitoring   = false
  ipv6         = false
  resize_disk  = true

  user_data    = data.template_file.admin_cloud_init.rendered
}
