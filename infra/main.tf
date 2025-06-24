###############################################################################
#  infra/main.tf – drop-in replacement
#  ————————————————————————————————————————————————————————————————————————
#  Includes:
#    • provider + variables
#    • common cloud-init (installs & starts Nginx, opens firewall)
#    • four droplets  (root / ui / admin / api) – ALL with identical user_data
#    • managed MySQL cluster + two schemas
#    • project + resource attachment
#    • output of all IPv4 addresses
###############################################################################

terraform {
  required_version = "~> 1.8"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

#########################
#  Variables
#########################

variable "do_token" {
  description = "DigitalOcean personal access token"
  type        = string
}

variable "ssh_fingerprint" {
  description = "Fingerprint of the SSH key already uploaded to DO"
  type        = string
}

variable "region" {
  type    = string
  default = "sfo3"
}

variable "domain" {
  type    = string
  default = "axialy.ai"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "droplet_image" {
  type    = string
  default = "ubuntu-22-04-x64"
}

#########################
#  Data sources & locals
#########################

data "digitalocean_ssh_key" "this" {
  fingerprint = var.ssh_fingerprint
}

# same user-data for every droplet: install nginx + open firewall
data "templatefile" "cloud_init" {
  template = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - systemctl enable --now nginx
      - ufw allow 'Nginx Full' || true
  EOF
}

locals {
  tags_common = ["axialy"]
}

#########################
#  Project
#########################

resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "All Axialy droplets and managed services"
  purpose     = "Web Application"
  environment = "Production"
}

#########################
#  Droplets (HTTP only)
#########################

resource "digitalocean_droplet" "root" {
  name   = var.domain                 # axialy.ai
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys = [data.digitalocean_ssh_key.this.id]
  tags     = concat(local.tags_common, ["www"])

  user_data = data.templatefile.cloud_init.rendered
}

resource "digitalocean_droplet" "ui" {
  name   = "ui.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys = [data.digitalocean_ssh_key.this.id]
  tags     = concat(local.tags_common, ["ui"])

  user_data = data.templatefile.cloud_init.rendered
}

resource "digitalocean_droplet" "admin" {
  name   = "admin.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys = [data.digitalocean_ssh_key.this.id]
  tags     = concat(local.tags_common, ["admin"])

  user_data = data.templatefile.cloud_init.rendered
}

resource "digitalocean_droplet" "api" {
  name   = "api.${var.domain}"
  region = var.region
  size   = var.droplet_size
  image  = var.droplet_image

  ssh_keys = [data.digitalocean_ssh_key.this.id]
  tags     = concat(local.tags_common, ["api"])

  # <----- Previously missing; now identical to the other droplets
  user_data = data.templatefile.cloud_init.rendered
}

##############################
#  Managed MySQL cluster
##############################

resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = var.region
  node_count = 1
  project_id = digitalocean_project.axialy.id
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

#########################
#  Attach everything to the project
#########################

resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.root.urn,
    digitalocean_droplet.ui.urn,
    digitalocean_droplet.admin.urn,
    digitalocean_droplet.api.urn,
    digitalocean_database_cluster.mysql.urn
  ]
}

#########################
#  Outputs
#########################

output "droplet_ips" {
  description = "IPv4 addresses of all droplets"
  value = {
    root  = digitalocean_droplet.root.ipv4_address
    ui    = digitalocean_droplet.ui.ipv4_address
    admin = digitalocean_droplet.admin.ipv4_address
    api   = digitalocean_droplet.api.ipv4_address
  }
}
