# infra/terraform/main.tf
###############################################################################
#  Axialy Admin-stack resources – NO outputs here, they live in outputs.tf
###############################################################################

#############################
#  SSH key for droplet
#############################
# When `ssh_pub_key` is provided, create a new key.
# Otherwise we rely on an existing key supplied via `ssh_key_id`.
resource "digitalocean_ssh_key" "axialy" {
  count      = var.ssh_pub_key != "" ? 1 : 0
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

#############################
#  Managed MySQL cluster
#############################
resource "digitalocean_database_cluster" "axialy" {
  name        = "axialy-cluster"
  engine      = "mysql"
  version     = "8"
  region      = var.region
  size        = "db-s-1vcpu-1gb"
  node_count  = 1
}

# Logical databases
resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

# Separate users
resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin_user"
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui_user"
}

#############################
#  Droplet hosting the Admin stack
#############################
resource "digitalocean_droplet" "admin" {
  name       = "axialy-admin-droplet"
  region     = var.region
  size       = "s-1vcpu-1gb"
  image      = "ubuntu-22-04-x64"
  ipv6       = true
  monitoring = true

  # Choose the SSH key:
  #   • use existing key if `ssh_key_id` is set
  #   • otherwise use the key we just created
  ssh_keys = var.ssh_key_id != "" ?
    [var.ssh_key_id] :
    [digitalocean_ssh_key.axialy[0].id]

  # cloud-init installs Docker and pulls the GHCR image
  user_data = file("${path.module}/cloud-init.yml")
}
