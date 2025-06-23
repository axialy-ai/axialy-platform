variable "do_token" {
  type        = string
  sensitive   = true
}

variable "ns_key" {          # populated from TF_VAR_ns_key (GitHub env)
  type        = string
  sensitive   = true
}

variable "ns_domain" {       # populated from TF_VAR_ns_domain
  type = string
}
