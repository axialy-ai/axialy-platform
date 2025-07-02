variable "do_token"        { type = string }
variable "ssh_pub_key"     { type = string }
variable "ssh_key_name"    { type = string default = "axialy-admin" }

variable "droplet_region"  { type = string default = "nyc1" }
variable "droplet_size"    { type = string default = "s-1vcpu-1gb" }
variable "droplet_image"   { type = string default = "docker-20-04" }

variable "namesilo_api_key" { type = string }
variable "domain_name"      { type = string }

variable "mysql_version"    { type = string default = "8" }
