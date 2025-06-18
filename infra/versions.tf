terraform {
  required_version = ">= 1.4"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.56.0"   # Latest as of June 2025
    }
  }
}

