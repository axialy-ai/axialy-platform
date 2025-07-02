terraform {
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean" }
    random       = { source = "hashicorp/random" }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# ─────────────────────────────  SSH Key  ──────────────────────────────────────
resource "digitalocean_ssh_key" "deployer" {
  name       = "axialy-deployer"
  public_key = var.pub_key
}

# ─────────────────────────────  DB Cluster  ───────────────────────────────────
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = "8"
  region     = var.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

# Always create a **new** service user each run so we have the password.
resource "random_password" "svc_pass" {
  length  = 24
  special = false
}

resource "digitalocean_database_user" "svc" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_platform_${terraform.workspace}"
  mysql_auth_plugin = "mysql_native_password"
  password   = random_password.svc_pass.result
}

# ─────────────────────────────  Droplet  ──────────────────────────────────────
resource "digitalocean_droplet" "admin" {
  name              = "axialy-admin"
  region            = var.region
  size              = var.droplet_size
  image             = var.droplet_image
  ssh_keys          = [digitalocean_ssh_key.deployer.fingerprint]
  monitoring        = true
  user_data         = "#cloud-config\nruncmd:\n  - apt-get update\n  - apt-get install -y docker.io"
}

# ─────────────────────────────  Outputs  ──────────────────────────────────────
output "droplet_ip"   { value = digitalocean_droplet.admin.ipv4_address }
output "db_host"      { value = digitalocean_database_cluster.axialy.host }
output "db_port"      { value = digitalocean_database_cluster.axialy.port }
output "db_username"  { value = digitalocean_database_user.svc.name }
output "db_password"  {
  value     = digitalocean_database_user.svc.password
  sensitive = true
}
