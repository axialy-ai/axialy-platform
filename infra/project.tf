###############################################################################
#  DigitalOcean Project  +  attach the two resources we create
###############################################################################

resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  description = "Infrastructure for the Axialy Admin product"
  purpose     = "Web Application"
  environment = "Production"
}

# Put the Admin droplet and the MySQL cluster **into** the project
resource "digitalocean_project_resources" "attach" {
  project   = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.admin.urn,
    digitalocean_database_cluster.mysql.urn,
  ]
}
