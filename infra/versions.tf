###############################################################################
# infra/versions.tf
#
# • Allow any stable 1.x Terraform release (1.5, 1.6, 1.7, 1.8 …)
# • Keep the DigitalOcean provider safely pinned at 2.53.x
###############################################################################

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.53.0"   # stays on the bug-free 2.53 line
    }
  }
}
