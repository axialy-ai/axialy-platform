###############################################################################
#  Axialy Admin-stack resources – NO outputs here, they live in outputs.tf
###############################################################################

#############################
#  SSH key for droplet
#############################
resource "digitalocean_ssh_key" "axialy" {
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

#############################
#  Managed MySQL cluster
#############################
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = "8"
  region     = var.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

# Two logical databases in the same cluster
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

# Separate users for each logical DB
resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin_user"
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui_user"
}

#############################
#  Droplet that hosts the Admin container
#############################
resource "digitalocean_droplet" "admin" {
  name       = "axialy-admin-droplet"
  region     = var.region
  size       = "s-1vcpu-1gb"
  image      = "ubuntu-22-04-x64"
  ipv6       = true
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.axialy.id]

  # cloud-init installs Docker and pulls the GHCR image
  user_data = file("${path.module}/cloud-init.yml")
}
