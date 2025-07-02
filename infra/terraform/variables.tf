variable "do_token"  { type = string }
variable "pub_key"   { type = string }          # SSH key for droplet
variable "region"    { type = string }

# droplet size & image – adjust if needed
variable "droplet_size"  { default = "s-1vcpu-1gb" }
variable "droplet_image" { default = "docker-20-04" }
