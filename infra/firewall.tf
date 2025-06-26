// infra/firewall.tf
// DigitalOcean firewall for every Droplet tagged "axialy"

resource "digitalocean_firewall" "web" {
  name = "axialy-web"

  # Attach by tag — every Droplet with this tag inherits the firewall.
  tags = ["axialy"]

  # ─────────────────────────
  # Inbound rules
  # ─────────────────────────

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # ─────────────────────────
  # Outbound rules
  # ─────────────────────────

  # Allow all outbound TCP
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound UDP
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow outbound ICMP (ping, traceroute, etc.)
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
