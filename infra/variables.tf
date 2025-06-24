variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

# 👉 NEW – fingerprint of the SSH key to inject into each droplet
variable "ssh_fingerprint" {
  description = "Fingerprint of the deploy SSH key (from DO → Settings → Security → SSH Keys)"
  type        = string
}

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
