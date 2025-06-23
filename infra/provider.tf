# infra/provider.tf
provider "digitalocean" {
  token = var.do_token
}
