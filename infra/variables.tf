###############################################################################
# infra/variables.tf
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
# SSH key fingerprint (Settings ▸ Security ▸ SSH Keys)
# ---------------------------------------------------------------------------
variable "ssh_fingerprint" {
  description = "Fingerprint of the deploy SSH key"
  type        = string
}

# ---------------------------------------------------------------------------
# Primary DNS domain – builds droplet hostnames
# ---------------------------------------------------------------------------
variable "domain" {
  description = "Primary DNS domain for the platform"
  type        = string
  default     = "axialy.ai"
}

# ---------------------------------------------------------------------------
# Image slug every droplet boots from
# ---------------------------------------------------------------------------
variable "droplet_image" {
  description = "DigitalOcean image slug to use for droplets"
  type        = string
  default     = "ubuntu-22-04-x64"
}

# ---------------------------------------------------------------------------
# Region + droplet size
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

# ---------------------------------------------------------------------------
# Managed-MySQL node size (used by cluster.tf)
# ---------------------------------------------------------------------------
variable "db_node_size" {
  description = "Managed MySQL node size slug"
  type        = string
  default     = "db-s-1vcpu-1gb"
}
