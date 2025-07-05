###############################################################################
#  Axialy Platform – Terraform VARIABLES
###############################################################################

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_pub_key" {
  description = "Public-key string (only used when you really need to create a key)"
  type        = string
  default     = ""
}

variable "ssh_key_id" {
  description = "ID of an existing DigitalOcean SSH key to inject into the Droplet"
  type        = string
}

variable "region" {
  description = "DO region"
  type        = string
  default     = "nyc3"
}

variable "ssh_pub_key_unused" {
  description = "Kept only for backward compatibility – do not use."
  type        = string
  default     = ""
  sensitive   = true
}
