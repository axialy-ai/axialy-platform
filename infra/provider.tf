terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"
    }
    namesilo = {
      source  = "namesilo/namesilo"
      version = "~> 1.2"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "namesilo" {
  api_key = var.ns_key
}
