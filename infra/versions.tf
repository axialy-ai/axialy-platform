terraform {
  required_version = ">= 1.8.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
    namesilo = {
      source  = "namesilo/namesilo"
      version = "~> 1.4"
    }
  }
}
