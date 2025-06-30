variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
}

variable "ssh_fingerprint" {
  description = "Fingerprint of the SSH key that will access the droplet"
  type        = string
}
