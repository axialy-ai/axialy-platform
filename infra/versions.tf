terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      # Use the newest 2.55.x patch that exists today—
      # stick to “2.x” but never jump to 3.x automatically.
      version = "~> 2.55"
    }
  }
}
