###############################################################################
# infra/main.tf – now *only* holds the project definition.
# Droplets live in droplets.tf, DB bits in cluster.tf.
###############################################################################

locals {
  common_tags = ["axialy"]
}

resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "All Axialy droplets and managed services"
  purpose     = "Web Application"
  environment = "Production"
}
