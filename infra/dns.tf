###############################################################################
# Keep A-records in NameSilo in sync with the droplets IPs
###############################################################################

locals {
  # Map: host-part  ->  IP address
  a_records = {
    "@",   = digitalocean_droplet.root.ipv4_address   # apex
    "www", = digitalocean_droplet.root.ipv4_address
    "admin" = digitalocean_droplet.admin.ipv4_address
    "ui"    = digitalocean_droplet.ui.ipv4_address
    "api"   = digitalocean_droplet.api.ipv4_address
  }
}

resource "namesilo_dns_record" "a_records" {
  for_each = local.a_records

  domain = var.ns_domain
  host   = each.key
  type   = "A"
  value  = each.value
  ttl    = 3600

  lifecycle {
    create_before_destroy = true   # zero downtime when IP changes
  }
}
