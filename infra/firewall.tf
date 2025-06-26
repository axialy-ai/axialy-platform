###############################################################################
#  DigitalOcean Firewalls
#  ──────────────────────
#  The buggy data source is gone – we manage firewalls explicitly instead.
###############################################################################

resource "digitalocean_firewall" "web" {
  name        = "axialy-web"
  droplet_ids = [
    digitalocean_droplet.ui.id,
    digitalocean_droplet.root.id,
  ]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "db" {
  name        = "axialy-db"
  droplet_ids = [digitalocean_droplet.api.id]

  inbound_rule {
    protocol            = "tcp"
    port_range          = "5432"
    source_firewall_ids = [digitalocean_firewall.web.id]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "firewall_ids" {
  value = {
    web = digitalocean_firewall.web.id
    db  = digitalocean_firewall.db.id
  }
}
