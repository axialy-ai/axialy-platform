###############################################################################
#  firewall.tf  –  always ensure a single "axialy-web" firewall exists
###############################################################################

terraform {
  required_version = ">= 1.5"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.53"
    }
  }
}

# -----------------------------------------------------------------------------
# 1) Discover any firewall that already has the desired name
# -----------------------------------------------------------------------------
data "digitalocean_firewalls" "all" {}

locals {
  matching_fws   = [for fw in data.digitalocean_firewalls.all.firewalls : fw
                    if fw.name == "axialy-web"]

  fw_found       = length(local.matching_fws) > 0
  fw_id          = local.fw_found ? one(local.matching_fws).id : null
}

# -----------------------------------------------------------------------------
# 2) If one exists, import it automatically during the apply phase
# -----------------------------------------------------------------------------
import {
  to   = digitalocean_firewall.web
  id   = local.fw_id
  when = local.fw_found          # only run when we actually found a match
}

# -----------------------------------------------------------------------------
# 3) Create a firewall only when none exists
# -----------------------------------------------------------------------------
resource "digitalocean_firewall" "web" {
  count = local.fw_found ? 0 : 1  # zero means “skip creation”

  name = "axialy-web"             # keep the name constant for discovery
  tags = ["axialy"]               # protects every droplet with this tag

  # ---------- inbound rules ----------
  inbound_rule {
    protocol        = "tcp"
    port_range      = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol        = "tcp"
    port_range      = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol        = "tcp"
    port_range      = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # ---------- outbound rules ----------
  outbound_rule {
    protocol                = "icmp"
    destination_addresses   = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol                = "tcp"
    port_range              = "all"
    destination_addresses   = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol                = "udp"
    port_range              = "all"
    destination_addresses   = ["0.0.0.0/0", "::/0"]
  }
}
