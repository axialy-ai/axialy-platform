###############################################################################
#  Axialy Admin – base infrastructure
#  • one MySQL cluster, two databases (Admin + UI), one user per DB
#  • one droplet that will run the PHP-FPM stack (installed later by Ansible)
###############################################################################

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

###############################################################################
# ─────────────────────────────── Variables ───────────────────────────────────
###############################################################################
variable "do_token"      { type = string }
variable "ssh_pub_key"   { type = string }
variable "region"        { type = string }

###############################################################################
# ────────────────────────────── Provider ─────────────────────────────────────
###############################################################################
provider "digitalocean" {
  token = var.do_token
}

###############################################################################
# ────────────────────────────── SSH key (one-time) ───────────────────────────
###############################################################################
resource "digitalocean_ssh_key" "axialy" {
  name       = "axialy-key"
  public_key = var.ssh_pub_key
}

###############################################################################
# ───────────────────────────── Password helpers ──────────────────────────────
###############################################################################
resource "random_password" "db_password_admin" {
  length  = 32
  special = true
}

resource "random_password" "db_password_ui" {
  length  = 32
  special = true
}

###############################################################################
# ──────────────────────── Managed MySQL cluster + DBs ────────────────────────
###############################################################################
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = 8
  region     = var.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_ADMIN"
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_user" "admin_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin_user"
  password   = random_password.db_password_admin.result
}

resource "digitalocean_database_user" "ui_user" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui_user"
  password   = random_password.db_password_ui.result
}

###############################################################################
# ─────────────────────────────── Droplet ─────────────────────────────────────
###############################################################################
resource "digitalocean_droplet" "admin" {
  name       = "axialy-admin-droplet"
  region     = var.region
  image      = "ubuntu-22-04-x64"
  size       = "s-1vcpu-1gb"
  ipv6       = true
  monitoring = true
  ssh_keys   = [digitalocean_ssh_key.axialy.fingerprint]

  # cloud-init will be supplied by Ansible later; placeholder is fine
  user_data = "#cloud-config\npackage_update: true\n"
}
