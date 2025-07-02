terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    namesilo = {               # community provider
      source  = "doitintl/namesilo"
      version = "0.3.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "namesilo" {
  api_key = var.namesilo_api_key
}
