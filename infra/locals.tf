# infra/locals.tf
locals {
  # every entry in this list gets the generic “static site” droplet build
  # (Nginx + PHP + env-file support from cloud-init)
  static_sites = [
    "root",
    "ui",
    "api",
    "admin"   # ← NEW
  ]
}
