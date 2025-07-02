# SSH key
resource "digitalocean_ssh_key" "admin" {
  name       = var.ssh_key_name
  public_key = var.ssh_pub_key
}

# Droplet
resource "digitalocean_droplet" "admin" {
  name              = "axialy-admin"
  region            = var.droplet_region
  size              = var.droplet_size
  image             = var.droplet_image
  ssh_keys          = [digitalocean_ssh_key.admin.fingerprint]
  monitoring        = true
  backups           = false
  ipv6              = true
  tags              = ["axialy-admin"]
}

# Simple firewall – http/https + ssh
resource "digitalocean_firewall" "admin" {
  name = "axialy-admin-fw"
  droplet_ids = [digitalocean_droplet.admin.id]

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

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Managed MySQL cluster
resource "digitalocean_database_cluster" "axialy" {
  name       = "axialy-cluster"
  engine     = "mysql"
  version    = var.mysql_version
  region     = var.droplet_region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_ui"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.axialy.id
  name       = "axialy_admin"
}

# DNS A record via NameSilo
data "digitalocean_droplet" "ip" {
  id = digitalocean_droplet.admin.id
}

resource "namesilo_dns_record" "admin_root" {
  domain = var.domain_name
  host   = "@"
  value  = data.digitalocean_droplet.ip.ipv4_address
  type   = "A"
  ttl    = 3600
}
