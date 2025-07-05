###############################################################################
#  Axialy Platform – Terraform VARIABLES
###############################################################################

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_pub_key" {
  description = "Public SSH key content to add to DigitalOcean"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}
