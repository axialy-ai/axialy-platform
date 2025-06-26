########################
#  Droplet definition  #
########################

variable "droplet_map" {
  description = "Map of site names to droplet tags"
  type        = map(string)
  default = {
    root  = "root"
    ui    = "ui"
    admin = "admin"
    api   = "api"
  }
}

# Use the same cloud-init template for every droplet
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.tpl")
}

resource "digitalocean_droplet" "sites" {
  for_each = var.droplet_map

  name              = (each.key == "root" ? "axialy.ai" : "${each.key}.axialy.ai")
  region            = "sfo3"
  size              = "s-1vcpu-1gb"
  image             = "ubuntu-22-04-x64"
  ipv6              = false
  graceful_shutdown = true

  # Your existing SSH key fingerprint variable
  ssh_keys = [var.ssh_fingerprint]

  # Tag each droplet with a global tag plus its role
  tags = ["axialy", each.value]

  # Cloud-init user-data
  user_data = data.template_file.cloud_init.rendered
}
