# infra/versions.tf
terraform {
  required_version = ">= 1.4"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
