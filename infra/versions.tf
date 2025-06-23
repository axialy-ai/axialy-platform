# infra/versions.tf
terraform {
  required_version = ">= 1.4"

  required_providers {
    # DigitalOcean – actual infrastructure we manage
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.55"
    }

    # Null – used in many HashiCorp examples; safe to keep
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # 👇 Explicitly declare the *real* NameSilo provider location.
    #    We don’t use any resources from it, but declaring it here
    #    satisfies Terraform Core when it scans legacy state/config.
    namesilo = {
      source  = "namesilo/namesilo"
      version = ">= 2.0"
    }
  }
}
