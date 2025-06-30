variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_fingerprint" {
  description = "Fingerprint of the deploy SSH key (shown in DO → Settings → Security)"
  type        = string
}

variable "region" {
  type    = string
  default = "sfo3"
}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}
