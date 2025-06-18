terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      # Stay on the newest 2.55.x patch (2.56.0 doesn’t exist yet)
      version = "~> 2.55"
    }
  }
}
