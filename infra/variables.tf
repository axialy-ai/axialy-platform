variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ns_key" {
  description = "NameSilo API key"
  type        = string
  sensitive   = true
}

variable "ns_domain" {
  description = "Domain managed at NameSilo (apex, e.g. example.com)"
  type        = string
}
