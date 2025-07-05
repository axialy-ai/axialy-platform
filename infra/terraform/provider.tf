###############################################################################
#  Axialy Platform – Terraform PROVIDERS
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# ── DigitalOcean (only one default configuration!) ───────────────────────────
provider "digitalocean" {
  token = var.do_token
}

/*  If, in the future, you need extra DigitalOcean credentials (e.g. for a
    different DO account or region), add them *with an alias*, e.g.:

provider "digitalocean" {
  alias = "secondary"
  token = var.secondary_do_token
}
*/
