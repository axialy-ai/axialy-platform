###############################################################################
#  firewall.tf  –  create axialy-web exactly once
###############################################################################

# ---------------------------------------------------------------------------
# 1) Discover whether a firewall named “axialy-web” already exists
# ---------------------------------------------------------------------------
data "digitalocean_firewalls" "all" {}

locals {
  fw_exists = length([
    for fw in data.digitalocean_firewalls.all.firewalls :
    fw if fw.name == "axialy-web"
  ]) > 0
}

# ---------------------------------------------------------------------------
# 2) Create the firewall only when it doesn’t exist
# ---------------------------------------------------------------------------
resource "digitalocean_firewall" "web" {
  count = local.fw_exists ? 0 : 1  # 0 → skip, 1 → create

  name = "axialy-web"
  tags = ["axialy"]                # protects every droplet with this tag

  # ---------------- inbound rules ----------------
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
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

  # ---------------- outbound rules ----------------
  outbound_rule {
    protocol               = "icmp"
    destination_addresses  = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol               = "tcp"
    port_range             = "all"
    destination_addresses  = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol               = "udp"
    port_range             = "all"
    destination_addresses  = ["0.0.0.0/0", "::/0"]
  }
}
