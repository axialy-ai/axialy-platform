###############################################################################
#  Providers – keep **exactly one** “terraform” and **one** default provider
###############################################################################
terraform {
  required_version = ">= 1.7.0"

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

provider "digitalocean" {
  token = var.do_token   # set by TF_VAR_do_token in the workflow
}
