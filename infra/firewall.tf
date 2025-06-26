# DigitalOcean Cloud-Firewall rules
resource "digitalocean_firewall" "web" {
  name = "axialy-web-allow-80-443"

  # ── inbound ───────────────────────
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

  # ── outbound (open) ───────────────
  outbound_rule {
    protocol              = "tcp"
    port_range            = "0"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # attach to every droplet tagged “axialy”
  droplet_tags = ["axialy"]
}
