locals {
  # hostname => IPv4 address (pulled from the droplet once it’s created)
  a_records = {
    "@"   = digitalocean_droplet.root.ipv4_address  # apex record
    "api" = digitalocean_droplet.root.ipv4_address
  }
}

resource "namesilo_dns_record" "a_records" {
  for_each = local.a_records

  domain = var.ns_domain
  host   = each.key
  type   = "A"
  value  = each.value
  ttl    = 3600

  # only the droplet changing its IP should force replacement
  replace_triggered_by = [
    digitalocean_droplet.root
  ]
}
