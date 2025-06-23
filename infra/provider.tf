provider "digitalocean" {
  token = var.do_token
}

provider "namesilo" {
  api_key = var.ns_key
  domain  = var.ns_domain
}
