# ── A-records we want in NameSilo ──────────────────────────────────────────────
locals {
  a_records = {
    "@"   = digitalocean_droplet.root.ipv4_address   # apex → root droplet
    "www" = digitalocean_droplet.root.ipv4_address   # www  → same root
    "api" = digitalocean_droplet.api.ipv4_address    # api  → api droplet
  }
}

resource "namesilo_dns_record" "a_records" {
  for_each = local.a_records

  domain = var.ns_domain
  host   = each.key
  value  = each.value
  type   = "A"
  ttl    = 3600

  lifecycle {
    # re-create DNS record when the referenced droplet is replaced
    replace_triggered_by = [
      digitalocean_droplet.root,   # safe – resource ref, not each.value
      digitalocean_droplet.api
    ]
  }
}
