# infra/droplets_static.tf
resource "digitalocean_droplet" "static_sites" {
  for_each  = toset(local.static_sites)      # ← now includes “admin”
  name      = "${each.key}.axialy.ai"
  region    = "sfo3"
  size      = "s-1vcpu-1gb"
  image     = "ubuntu-22-04-x64"

  ssh_keys  = [var.ssh_fingerprint]
  tags      = ["axialy", each.key]

  user_data = data.template_file.static_site.rendered
}
