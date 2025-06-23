# ── Provider configuration ─────────────────────────────────────────────────────
provider "digitalocean" {
  token = var.do_token
}

provider "namesilo" {
  api_key = var.ns_key
}
