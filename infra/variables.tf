###############################################################################
# variables.tf – **DROP THIS IN `infra/variables.tf` (overwrite the old one)**
###############################################################################

# ---------------------------------------------------------------------------
# DigitalOcean credentials
# ---------------------------------------------------------------------------
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# SSH key that Terraform injects into every droplet
# (fingerprint is the value shown in DO ▸ Settings ▸ Security ▸ SSH Keys)
# ---------------------------------------------------------------------------
variable "ssh_fingerprint" {
  description = "Fingerprint of the deploy SSH key"
  type        = string
}

# ---------------------------------------------------------------------------
# Primary DNS domain – used to build droplet hostnames
#   root   →  axially.ai
#   ui     →  ui.axialy.ai
#   admin  →  admin.axialy.ai
#   api    →  api.axialy.ai
# ---------------------------------------------------------------------------
variable "domain" {
  description = "Primary DNS domain for the platform"
  type        = string
  default     = "axialy.ai"
}

# ---------------------------------------------------------------------------
# Image slug every droplet will boot from
# ---------------------------------------------------------------------------
variable "droplet_image" {
  description = "DigitalOcean image slug to use for droplets"
  type        = string
  default     = "ubuntu-22-04-x64"
}

# ---------------------------------------------------------------------------
# Region and size can still be overridden, but the defaults match the old repo
# ---------------------------------------------------------------------------
variable "region" {
  description = "Region to create resources in"
  type        = string
  default     = "sfo3"
}

variable "droplet_size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-1vcpu-1gb"
}
