##############################################################################
# ONE authoritative A-record per hostname – managed by the namesilo provider
##############################################################################

locals {
  # Droplet-to-hostname mapping
  host_ip_map = {
    "@"    = digitalocean_droplet.root.ipv4_address   # apex
    "www"  = digitalocean_droplet.root.ipv4_address   # www → same IP
    "admin" = digitalocean_droplet.admin.ipv4_address
    "ui"    = digitalocean_droplet.ui.ipv4_address
    "api"   = digitalocean_droplet.api.ipv4_address
  }
}

resource "namesilo_dns_record" "a_records" {
  for_each = local.host_ip_map

  domain = var.ns_domain
  host   = each.key          # "@" | "www" | "admin" | ...
  type   = "A"
  value  = each.value
  ttl    = 3600

  # if a droplet is recreated and gets a new IP, force record replace
  lifecycle {
    replace_triggered_by = [ each.value ]
  }
}
