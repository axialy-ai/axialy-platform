# infra/locals.tf
locals {
  # Every hostname in var.static_sites gets the generic “static-site” build.
  # The Admin droplet uses its dedicated cloud-init template instead.
  static_sites = var.static_sites            # ← no hard-coded “admin” here
}
