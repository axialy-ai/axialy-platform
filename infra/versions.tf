terraform {
  required_version = ">= 1.5.0, < 1.9.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      # ←← 2.55.0+ breaks database-db creation.  2.54.x is good.
      version = "~> 2.54.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
