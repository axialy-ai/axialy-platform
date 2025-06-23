###############################################################################
# Providers (DigitalOcean + NameSilo) and required versions
###############################################################################

terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"          # keep using the 2.55-line
    }

    namesilo = {
      source  = "namesilo/namesilo"
      version = "~> 1.4"           # latest stable at time of writing
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "namesilo" {
  api_key = var.ns_key           # pulled from GitHub Secrets
}
