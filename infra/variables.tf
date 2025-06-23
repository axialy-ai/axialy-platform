# DigitalOcean
variable "do_token"      { description = "DigitalOcean API token"   type = string  sensitive = true }

# NameSilo
variable "ns_key"        { description = "NameSilo API key"         type = string  sensitive = true }
variable "ns_domain"     { description = "Managed domain name"      type = string  default = "axialy.ai" }

# misc
variable "region"        { description = "Region to create resources in" type = string  default = "sfo3" }
variable "droplet_size"  { description = "Droplet size slug"             type = string  default = "s-1vcpu-1gb" }
