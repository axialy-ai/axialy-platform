# ── Input variables ────────────────────────────────────────────────────────────
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
  description = "Domain name managed at NameSilo"
  type        = string
}
