########################
#  Droplet definition  #
########################

variable "droplet_map" {
  description = "Map of site identifiers to role tags"
  type        = map(string)
  default = {
    root  = "root"
    ui    = "ui"
    admin = "admin"
    api   = "api"
  }
}

# ─────────────────────────────────────────────────────────────
# Shared cloud-init (lives under infra/cloud-init/)
# ─────────────────────────────────────────────────────────────
data "template_file" "cloud_init" {
  # ⚠️  ← was `${path.module}/cloud-init.tpl`
  template = file("${path.module}/cloud-init/cloud-init.tpl")
}

resource "digitalocean_droplet" "sites" {
  for_each = var.droplet_map

  name              = each.key == "root" ? "axialy.ai" : "${each.key}.axialy.ai"
  region            = var.region          # from variables.tf
  size              = var.droplet_size    # from variables.tf
  image             = var.droplet_image   # from variables.tf
  ipv6              = false
  graceful_shutdown = true

  ssh_keys = [var.ssh_fingerprint]

  # “axialy” = firewall selector; second tag = role
  tags = ["axialy", each.value]

  user_data = data.template_file.cloud_init.rendered
}
