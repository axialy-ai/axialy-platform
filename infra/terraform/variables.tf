variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_pub_key" {
  description = "Public-key string used to log in to the droplet"
  type        = string
}

variable "region" {
  description = "DO region"
  type        = string
  default     = "nyc3"
}
