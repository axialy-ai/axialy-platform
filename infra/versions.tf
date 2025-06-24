###############################################################################
# Lock the DigitalOcean provider at 2.54.x
# 2.55.0 and later have a bug that breaks `digitalocean_database_db` creation
###############################################################################

terraform {
  required_version = ">= 1.5.0, < 1.9.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.54.0"   # ← pin here
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
