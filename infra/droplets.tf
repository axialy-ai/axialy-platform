############################################
#  Axialy - authoritative droplet template #
############################################
#   ▸ Replaces ALL former per-droplet and
#     static_sites definitions.
#   ▸ Produces a single resource set:
#       digitalocean_droplet.sites["…"]
############################################

terraform {
  required_version = ">= 1.4"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.53"
    }
  }
}

# ─────────── VARIABLES ───────────
variable "region" {
  description = "DigitalOcean region for all droplets"
  type        = string
  default     = "sfo3"
}

variable "ssh_fingerprint" {
  description = "Fingerprint of the SSH key already uploaded to DO"
  type        = string
}

variable "droplet_names" {
  description = "Canonical list of Axialy droplets"
  type        = list(string)
  default     = ["root", "ui", "api", "admin"]
}

locals {
  image          = "ubuntu-22-04-x64"
  cloudinit_dir  = "${path.module}/cloudinit"
}

# ─────────── SINGLE DROPLET RESOURCE ───────────
resource "digitalocean_droplet" "sites" {
  for_each = toset(var.droplet_names)

  name              = "${each.key}.axialy.ai"
  region            = var.region
  size              = "s-1vcpu-1gb"
  image             = local.image
  ssh_keys          = [var.ssh_fingerprint]

  ipv6              = false
  monitoring        = false
  backups           = false
  graceful_shutdown = true

  # Optional cloud-init; comment out if unused
  user_data = fileexists("${local.cloudinit_dir}/${each.key}.yml")
              ? file("${local.cloudinit_dir}/${each.key}.yml")
              : null

  tags = ["axialy", each.key]
}

# ─────────── PROJECT ATTACHMENT ───────────
resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [for d in digitalocean_droplet.sites : d.urn]
}
