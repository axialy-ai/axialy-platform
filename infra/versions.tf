###############################################################################
#  infra/versions.tf
#  • Locks Terraform itself at 1.8.x
#  • Pins the DigitalOcean provider one step *before* the buggy 2.54/2.55 line
###############################################################################

terraform {
  required_version = ">= 1.5.0, < 1.9.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.53.0"   # ← roll back one minor to dodge the DB-inconsistency bug
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
