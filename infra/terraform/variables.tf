# infra/terraform/variables.tf
###############################################################################
#  Axialy Platform – Terraform VARIABLES
###############################################################################

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_pub_key" {
  description = "Public-key string (use when you want Terraform to create a new key)"
  type        = string
  default     = ""
}

variable "ssh_key_id" {
  description = <<-EOT
    ID **or fingerprint** of an existing DigitalOcean SSH key to inject into the
    Droplet. Leave empty to have Terraform create a key from `ssh_pub_key`.
  EOT
  type    = string
  default = ""
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "ssh_pub_key_unused" {
  description = "Kept only for backward compatibility – do not use."
  type        = string
  default     = ""
  sensitive   = true
}
