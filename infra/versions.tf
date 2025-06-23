terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"   # lock to the newest 2.55.x patch
    }
  }
}
